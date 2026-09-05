<script>
import { GlButton, GlCollapsibleListbox } from '@gitlab/ui';
import { debounce, xor } from 'lodash-es';
import { s__, sprintf } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import getGroupChildrenQuery from '../graphql/get_group_children.query.graphql';
import getSubgroupProjectsQuery from '../graphql/get_subgroup_projects.query.graphql';
import getTopLevelGroupsQuery from '../graphql/get_top_level_groups.query.graphql';
import searchNamespacesQuery from '../graphql/search_namespaces.query.graphql';
import searchNamespacesGlobalQuery from '../graphql/search_namespaces_global.query.graphql';
import ScopePickerItem from './scope_picker_item.vue';

// Keeps a placeholder row's value from colliding with a real namespace path.
const EMPTY_ITEM_SUFFIX = '::empty';

export default {
  name: 'AnalyticsDashboardScopePicker',
  components: {
    GlButton,
    GlCollapsibleListbox,
    ScopePickerItem,
  },
  props: {
    // Omit to browse the user's own top-level groups instead of one group's contents, which is
    // what the instance-level Explore page needs: it has no group to scope to.
    groupFullPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['change', 'error'],
  data() {
    return {
      namespace: null,
      topLevelGroups: [],
      // The pick is held as the namespace itself, not its path. A path would have to be resolved
      // against the loaded namespaces on every read, and a second search replaces the results the
      // pick may have come from, so by then there would be nothing left to resolve it to.
      selectedNamespace: null,
      // The top-level group's projects arrive with the group itself, so it opens without a fetch.
      expandedPaths: this.groupFullPath ? [this.groupFullPath] : [],
      // Each expanded subgroup's projects, flattened across its own subgroups, keyed by path.
      subgroupProjects: {},
      searchTerm: '',
      // Whichever of the two search queries the current mode uses. Only one is ever live.
      rootedResults: null,
      globalResults: null,
    };
  },
  apollo: {
    namespace: {
      query: getGroupChildrenQuery,
      variables() {
        return { fullPath: this.groupFullPath };
      },
      update: ({ group }) => group,
      skip() {
        return !this.groupFullPath;
      },
      error(error) {
        this.$emit('error', error);
        captureException(error);
      },
    },
    topLevelGroups: {
      query: getTopLevelGroupsQuery,
      update: ({ groups }) => groups?.nodes ?? [],
      skip() {
        return Boolean(this.groupFullPath);
      },
      error(error) {
        this.$emit('error', error);
        captureException(error);
      },
    },
    rootedResults: {
      query: searchNamespacesQuery,
      variables() {
        // Trimmed, because `hasSearch` decides whether to run on the trimmed value.
        return { fullPath: this.groupFullPath, search: this.searchTerm.trim() };
      },
      update: ({ group }) => ({
        groups: group?.descendantGroups?.nodes ?? [],
        projects: group?.projects?.nodes ?? [],
      }),
      skip() {
        return !this.groupFullPath || !this.hasSearch;
      },
      error(error) {
        this.$emit('error', error);
        captureException(error);
      },
    },
    globalResults: {
      query: searchNamespacesGlobalQuery,
      variables() {
        return { search: this.searchTerm.trim() };
      },
      update: ({ groups, projects }) => ({
        groups: groups?.nodes ?? [],
        projects: projects?.nodes ?? [],
      }),
      skip() {
        return Boolean(this.groupFullPath) || !this.hasSearch;
      },
      error(error) {
        this.$emit('error', error);
        captureException(error);
      },
    },
  },
  computed: {
    isLoading() {
      const query = this.groupFullPath ? 'namespace' : 'topLevelGroups';

      return this.$apollo.queries[query].loading;
    },
    hasSearch() {
      return this.searchTerm.trim().length > 0;
    },
    isSearching() {
      const query = this.groupFullPath ? 'rootedResults' : 'globalResults';

      return this.$apollo.queries[query].loading;
    },
    searchResults() {
      return this.groupFullPath ? this.rootedResults : this.globalResults;
    },
    projects() {
      return this.namespace?.projects.nodes ?? [];
    },
    subgroups() {
      return this.namespace?.descendantGroups.nodes ?? [];
    },
    groupNamespace() {
      return this.namespace ? this.asNamespace(this.namespace) : null;
    },
    // Every namespace behind a row that can currently be clicked, which is what a click's path is
    // turned back into an object against. It only has to cover what is on screen, because the pick
    // is captured at click time and does not depend on this afterwards.
    knownNamespaces() {
      const subgroupProjects = Object.values(this.subgroupProjects).flatMap(
        ({ projects }) => projects ?? [],
      );

      return [
        this.namespace,
        ...this.projects,
        ...this.subgroups,
        ...this.topLevelGroups,
        ...subgroupProjects,
        ...(this.searchResults?.groups ?? []),
        ...(this.searchResults?.projects ?? []),
      ]
        .filter(Boolean)
        .map((namespace) => this.asNamespace(namespace));
    },
    selectedPath() {
      return this.selectedNamespace?.fullPath ?? '';
    },
    toggleText() {
      return this.selectedNamespace?.name ?? s__('AnalyticsDashboards|Select a group or project');
    },
    // Rooted mode groups its rows under two headers. Rootless has one kind of top-level row, so
    // it passes a flat list; the listbox takes either shape, as long as they are not mixed.
    items() {
      if (this.hasSearch) return this.searchItems;

      return this.groupFullPath ? this.rootedSections : this.rootlessItems;
    },
    // Search spans the whole hierarchy, so results are listed flat rather than placed back into
    // the tree they came from. Headers by kind would only assert an ordering the two queries
    // cannot actually rank against each other; the row icons already say which is which. Every
    // row names its parent, since a match can come from any depth.
    searchItems() {
      const { groups = [], projects = [] } = this.searchResults ?? {};

      return [...groups, ...projects].map(this.asResultItem);
    },
    // Each top-level group is a row of its own, opening into its own projects the way the root
    // row does in rooted mode. Subgroups are left to search.
    rootlessItems() {
      return this.topLevelGroups.flatMap((group) => [
        { ...this.asItem(this.asNamespace(group)), expandable: group.projectsCount > 0 },
        ...this.subgroupItems(group.fullPath),
      ]);
    },
    rootedSections() {
      if (!this.namespace) return [];

      return [
        {
          // Not escaped by sprintf: this lands in a text interpolation, which Vue escapes, so
          // escaping here too would render an ampersand in a group name as `&amp;`.
          text: sprintf(
            s__('AnalyticsDashboards|Projects in top-level group (%{name})'),
            { name: this.namespace.name },
            false,
          ),
          options: [
            { ...this.asItem(this.groupNamespace), expandable: this.projects.length > 0 },
            ...(this.isExpanded(this.groupFullPath)
              ? this.projects.map((project) => ({
                  ...this.asItem(this.asNamespace(project)),
                  nested: true,
                }))
              : []),
          ],
        },
        {
          text: s__('AnalyticsDashboards|Subgroups incl. nested'),
          options: this.subgroups.flatMap((subgroup) => [
            {
              ...this.asItem(this.asNamespace(subgroup)),
              // Both counts are direct-only, so this is as close as the API gets to "has
              // content" without an unbatched per-row query. See the No projects row below.
              expandable: subgroup.projectsCount > 0 || subgroup.descendantGroupsCount > 0,
            },
            ...this.subgroupItems(subgroup.fullPath),
          ]),
        },
      ].filter(({ options }) => options.length);
    },
    // A flat view of whichever shape `items` took, for resolving the selection against.
    flatItems() {
      return this.items.flatMap((item) => item.options ?? item);
    },
    selectedPaths() {
      return this.flatItems.filter(({ selected }) => selected).map(({ value }) => value);
    },
  },
  watch: {
    // Everything loaded so far belongs to the old root, and the selection may no longer be in
    // scope, so start over rather than showing a mix of the two.
    groupFullPath(fullPath) {
      this.expandedPaths = fullPath ? [fullPath] : [];
      this.subgroupProjects = {};
      this.selectedNamespace = null;
      // Cancelled as well as cleared: a debounce still pending would otherwise land afterwards
      // and search the new root for a term typed against the old one.
      this.onSearch.cancel();
      this.searchTerm = '';
      this.$emit('change', null);
    },
  },
  beforeDestroy() {
    this.onSearch.cancel();
  },
  created() {
    // Vue re-binds everything in `methods`, and that drops lodash's `cancel`, so the debounced
    // handler has to be built per instance, so cancelling it cancels only this one's.
    this.onSearch = debounce(this.setSearchTerm, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    asNamespace({ id, name, fullName, fullPath, __typename }) {
      return { id, name, fullName, fullPath, type: __typename };
    },
    asItem({ name, fullPath, type }) {
      // A selected group covers everything beneath it, so those items cannot be picked on their own.
      const isLockedByAncestor =
        Boolean(this.selectedPath) && fullPath.startsWith(`${this.selectedPath}/`);

      return {
        value: fullPath,
        text: name,
        namespaceType: type,
        selected: this.selectedPath === fullPath || isLockedByAncestor,
        indeterminate: this.hasSelectedDescendant(fullPath),
        disabled: isLockedByAncestor,
        expanded: this.isExpanded(fullPath),
        expanding: this.isExpanded(fullPath) && Boolean(this.subgroupProjects[fullPath]?.isLoading),
      };
    },
    asResultItem(namespace) {
      return {
        ...this.asItem(this.asNamespace(namespace)),
        parentName: namespace.namespace?.name ?? null,
      };
    },
    // The rows an expanded subgroup reveals. Nothing until its fetch lands.
    subgroupItems(fullPath) {
      if (!this.isExpanded(fullPath)) return [];

      const { projects } = this.subgroupProjects[fullPath] ?? {};
      if (!projects) return [];

      // A subgroup can look expandable on its direct counts and still hold nothing, so say so
      // rather than leaving the expand looking broken.
      if (!projects.length) {
        return [
          {
            value: `${fullPath}${EMPTY_ITEM_SUFFIX}`,
            text: s__('AnalyticsDashboards|No projects'),
            placeholder: true,
            disabled: true,
          },
        ];
      }

      // Projects arrive pre-flattened, so they render at one level whatever their real depth.
      // Naming the parent only helps for projects below the subgroup that was expanded.
      return projects.map((project) => ({
        ...this.asItem(this.asNamespace(project)),
        nested: true,
        parentName: project.namespace?.fullPath === fullPath ? null : project.namespace?.name,
      }));
    },
    isExpanded(fullPath) {
      return this.expandedPaths.includes(fullPath);
    },
    hasSelectedDescendant(fullPath) {
      return this.selectedPath.startsWith(`${fullPath}/`);
    },
    async toggleExpanded(fullPath) {
      if (this.isExpanded(fullPath)) {
        this.expandedPaths = this.expandedPaths.filter((path) => path !== fullPath);
        return;
      }

      this.expandedPaths = [...this.expandedPaths, fullPath];

      // The top-level group's projects came with the group itself, and a subgroup is fetched
      // once -- including while its first fetch is still in flight.
      const cached = this.subgroupProjects[fullPath];
      if (fullPath === this.groupFullPath || cached?.projects || cached?.isLoading) return;

      await this.loadSubgroupProjects(fullPath);
    },
    async loadSubgroupProjects(fullPath) {
      this.subgroupProjects = {
        ...this.subgroupProjects,
        [fullPath]: { isLoading: true, projects: null },
      };

      try {
        const { data } = await this.$apollo.query({
          query: getSubgroupProjectsQuery,
          // Rooted mode only ever expands subgroups, and rootless only top-level groups, so the
          // mode decides whether the whole tree or just the group's own projects is wanted.
          variables: { fullPath, includeSubgroups: Boolean(this.groupFullPath) },
        });

        this.subgroupProjects = {
          ...this.subgroupProjects,
          // A subgroup can go missing between the parent query and this one, which comes back
          // as a successful null rather than an error.
          [fullPath]: { isLoading: false, projects: data.group?.projects?.nodes ?? [] },
        };
      } catch (error) {
        // Collapse and forget the row, so expanding it again retries the fetch.
        const { [fullPath]: failed, ...rest } = this.subgroupProjects;
        this.subgroupProjects = rest;
        this.expandedPaths = this.expandedPaths.filter((path) => path !== fullPath);

        this.$emit('error', error);
        captureException(error);
      }
    },
    onSelect(paths) {
      // The listbox reports the whole selection, but only one item can change per click and the
      // picker is single-select, so apply that item's toggle rather than taking the list as given.
      const [fullPath] = xor(paths, this.selectedPaths);

      // Ticking an item replaces the selection. Unticking it, or clearing an item left
      // indeterminate by a descendant, empties the selection instead.
      const clearsSelection =
        this.selectedPath === fullPath || this.hasSelectedDescendant(fullPath);

      this.selectedNamespace = clearsSelection
        ? null
        : (this.knownNamespaces.find((namespace) => namespace.fullPath === fullPath) ?? null);

      this.$emit('change', this.selectedNamespace);
    },
    setSearchTerm(searchTerm) {
      this.searchTerm = searchTerm;
    },
    // Closing is what dismisses the picker, so Done just closes.
    onDone() {
      this.$refs.listbox.close();
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    ref="listbox"
    class="analytics-scope-picker"
    multiple
    fluid-width
    :items="items"
    :selected="selectedPaths"
    :toggle-text="toggleText"
    :header-text="s__('AnalyticsDashboards|Scope')"
    :loading="isLoading"
    searchable
    :searching="isSearching"
    :search-placeholder="s__('AnalyticsDashboards|Search groups and projects')"
    :no-results-text="s__('AnalyticsDashboards|No groups or projects found')"
    @search="onSearch"
    @select="onSelect"
  >
    <template #list-item="{ item }">
      <span
        v-if="item.placeholder"
        class="-gl-m-2 gl-flex gl-items-center gl-gap-2 gl-pl-5 gl-text-subtle"
        data-testid="scope-picker-empty-item"
      >
        <!-- Reserve the chevron's width so the text lines up with the projects it stands in for. -->
        <span class="gl-w-6 gl-shrink-0"></span>
        {{ item.text }}
      </span>

      <scope-picker-item v-else v-bind="item" @toggle-expanded="toggleExpanded(item.value)" />
    </template>

    <template #footer>
      <div class="gl-border-t gl-flex gl-justify-end gl-border-t-dropdown gl-p-3">
        <gl-button category="primary" variant="confirm" size="small" @click="onDone">
          {{ __('Done') }}
        </gl-button>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>

<style>
/* Each item draws its own checkbox, so the listbox's built-in check indicator is redundant. */
.analytics-scope-picker .gl-new-dropdown-item-check-icon {
  display: none;
}
</style>
