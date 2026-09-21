<script>
import { GlButton, GlCollapsibleListbox } from '@gitlab/ui';
import { debounce, xor } from 'lodash-es';
import { s__, sprintf } from '~/locale';
import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import getSubgroupProjectsQuery from '../graphql/get_subgroup_projects.query.graphql';
import getTopLevelGroupsQuery from '../graphql/get_top_level_groups.query.graphql';
import searchNamespacesGlobalQuery from '../graphql/search_namespaces_global.query.graphql';
import getScopeNamespaceQuery from '../graphql/get_scope_namespace.query.graphql';
import {
  SCOPE_PICKER_ITEM_TYPE_GROUP,
  SCOPE_PICKER_ITEM_TYPE_PROJECT,
  SCOPE_PICKER_ITEM_TYPE_LOAD_MORE,
} from './constants';
import ScopePickerItem from './scope_picker_item.vue';

// The rows are typed in the picker's own terms, so a namespace's typename maps onto one.
const ITEM_TYPE_BY_TYPENAME = {
  [TYPENAME_GROUP]: SCOPE_PICKER_ITEM_TYPE_GROUP,
  [TYPENAME_PROJECT]: SCOPE_PICKER_ITEM_TYPE_PROJECT,
};

// Keeps a placeholder row's value from colliding with a real namespace path.
const EMPTY_ITEM_SUFFIX = '::empty';
const LOAD_MORE_ITEM_SUFFIX = '::load-more';

export default {
  name: 'AnalyticsDashboardScopePicker',
  components: {
    GlButton,
    GlCollapsibleListbox,
    ScopePickerItem,
  },
  props: {
    // A namespace path to start selected (ex. URL param on page load)
    initialPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['change', 'error'],
  data() {
    return {
      topLevelGroups: [],
      topLevelGroupsPageInfo: null,
      isLoadingTopLevelGroups: false,
      // The pick is held as the namespace itself, not its path. A path would have to be resolved
      // against the loaded namespaces on every read, and a second search replaces the results the
      // pick may have come from, so by then there would be nothing left to resolve it to.
      selectedNamespace: null,
      expandedPaths: [],
      // Each expanded group's projects, flattened across the subgroups below it, keyed by path.
      // Alongside them, the group's loading state and the cursor the next page starts from.
      subgroupProjects: {},
      searchTerm: '',
      initialScope: null,
      searchResults: null,
    };
  },
  apollo: {
    searchResults: {
      query: searchNamespacesGlobalQuery,
      variables() {
        // Trimmed, because `hasSearch` decides whether to run on the trimmed value.
        return { search: this.searchTerm.trim() };
      },
      update: ({ groups, projects }) => ({
        groups: groups?.nodes ?? [],
        projects: projects?.nodes ?? [],
      }),
      skip() {
        return !this.hasSearch;
      },
      error(error) {
        this.$emit('error', error);
        captureException(error);
      },
    },
    initialScope: {
      query: getScopeNamespaceQuery,
      variables() {
        return { fullPath: this.initialPath, fullPaths: [this.initialPath] };
      },
      // Only update if a valid group/project is returned
      update: ({ group, projects }) => group ?? projects?.nodes?.[0] ?? null,
      // The page echoes the current selection back through `initialPath`, so a path that is
      // already selected needs no lookup -- the click resolved that namespace already.
      skip() {
        return !this.initialPath || this.initialPath === this.selectedPath;
      },
      error(error) {
        this.$emit('error', error);
        captureException(error);
      },
    },
  },
  computed: {
    isLoadingFirstPage() {
      return this.isLoadingTopLevelGroups && !this.topLevelGroups.length;
    },
    hasSearch() {
      return this.searchTerm.trim().length > 0;
    },
    isSearching() {
      return this.$apollo.queries.searchResults.loading;
    },
    // Every namespace behind a row that can currently be clicked, which is what a click's path is
    // turned back into an object against. It only has to cover what is on screen, because the pick
    // is captured at click time and does not depend on this afterwards.
    knownNamespaces() {
      const subgroupProjects = Object.values(this.subgroupProjects).flatMap(
        ({ projects }) => projects ?? [],
      );

      return [
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
    items() {
      return this.hasSearch ? this.searchItems : this.groupItems;
    },
    // Search spans the whole hierarchy, so results are listed flat rather than placed back into
    // the tree they came from. Headers by kind would only assert an ordering the two queries
    // cannot actually rank against each other; the row icons already say which is which. Every
    // row names its parent, since a match can come from any depth.
    searchItems() {
      const { groups = [], projects = [] } = this.searchResults ?? {};

      return [...groups, ...projects].map(this.asResultItem);
    },
    // Each top-level group is a row of its own, opening into every project beneath it. Both
    // counts are direct-only, so this is as close as the API gets to "has content" without an
    // unbatched per-row query. See the No projects row below.
    groupItems() {
      const items = this.topLevelGroups.flatMap((group) => [
        {
          ...this.asItem(this.asNamespace(group)),
          expandable: group.projectsCount > 0 || group.descendantGroupsCount > 0,
        },
        ...this.subgroupItems(group),
      ]);

      if (this.topLevelGroupsPageInfo?.hasNextPage) {
        items.push(this.asLoadMoreItem({ isLoading: this.isLoadingTopLevelGroups }));
      }

      return items;
    },
    // Rows locked by a selected ancestor render checked, so the options behind them have to agree.
    // The pick itself may be on none of them -- not paged in yet, or filtered out by a search --
    // and it still has to count, or the listbox greys the toggle as if nothing were selected.
    selectedPaths() {
      const visible = this.items.filter(({ selected }) => selected).map(({ value }) => value);

      return this.selectedPath && !visible.includes(this.selectedPath)
        ? [this.selectedPath, ...visible]
        : visible;
    },
  },
  watch: {
    initialScope(namespace) {
      // Ignore initialScope if another namespace was already selected.
      if (!namespace || this.selectedNamespace) return;

      this.selectedNamespace = this.asNamespace(namespace);
      this.$emit('change', this.selectedNamespace);
    },
  },
  beforeDestroy() {
    this.onSearch.cancel();
  },
  created() {
    // Vue re-binds everything in `methods`, and that drops lodash's `cancel`, so the debounced
    // handler has to be built per instance, so cancelling it cancels only this one's.
    this.onSearch = debounce(this.setSearchTerm, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);

    this.loadTopLevelGroups();
  },
  methods: {
    asNamespace({ id, name, fullName, fullPath, __typename }) {
      return { id, name, fullName, fullPath, type: __typename };
    },
    asItem({ name, fullPath, type }) {
      // A selected group covers everything beneath it, so those items cannot be picked on their own.
      const isLockedByAncestor =
        Boolean(this.selectedPath) && fullPath.startsWith(`${this.selectedPath}/`);

      const { isLoading, projects } = this.subgroupProjects[fullPath] ?? {};

      return {
        value: fullPath,
        text: name,
        itemType: ITEM_TYPE_BY_TYPENAME[type],
        selected: this.selectedPath === fullPath || isLockedByAncestor,
        indeterminate: this.hasSelectedDescendant(fullPath),
        disabled: isLockedByAncestor,
        expanded: this.isExpanded(fullPath),
        // Only the first page leaves the row with nothing to show, so later pages report on the
        // Load more button they were asked for from instead.
        expanding: this.isExpanded(fullPath) && Boolean(isLoading) && !projects,
      };
    },
    asResultItem(namespace) {
      return {
        ...this.asItem(this.asNamespace(namespace)),
        parentName: namespace.namespace?.name ?? null,
      };
    },
    // A row of its own at the end of the list it extends, rather than a single footer control,
    // because every expanded group carries one of its own.
    asLoadMoreItem({ fullPath = null, name = null, isLoading }) {
      return {
        value: `${fullPath ?? ''}${LOAD_MORE_ITEM_SUFFIX}`,
        // Names the list it extends, every one of these rows otherwise reading alike. Not escaped
        // by sprintf: Vue escapes the interpolation, so escaping here as well would render a group
        // called "Sales & Marketing" as `Sales &amp; Marketing`.
        text: name
          ? sprintf(s__('AnalyticsDashboards|Load more projects in %{name}'), { name }, false)
          : s__('AnalyticsDashboards|Load more groups'),
        itemType: SCOPE_PICKER_ITEM_TYPE_LOAD_MORE,
        // The row only carries the button, so there is nothing about it to select.
        disabled: true,
        nested: Boolean(fullPath),
        loading: Boolean(isLoading),
      };
    },
    // The rows an expanded group reveals. Nothing until its fetch lands.
    subgroupItems({ fullPath, name }) {
      if (!this.isExpanded(fullPath)) return [];

      const { projects, pageInfo, isLoading } = this.subgroupProjects[fullPath] ?? {};
      if (!projects) return [];

      // A group can look expandable on its direct counts and still hold nothing -- its projects
      // may all be archived, or its subgroups may be empty. Say so rather than leaving the
      // expand looking broken.
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
      const items = projects.map((project) => ({
        ...this.asItem(this.asNamespace(project)),
        nested: true,
        parentName: project.namespace?.fullPath === fullPath ? null : project.namespace?.name,
      }));

      if (pageInfo?.hasNextPage) {
        items.push(this.asLoadMoreItem({ fullPath, name, isLoading }));
      }

      return items;
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

      // A group is fetched once -- including while its first fetch is still in flight.
      const cached = this.subgroupProjects[fullPath];
      if (cached?.projects || cached?.isLoading) return;

      await this.loadSubgroupProjects(fullPath);
    },
    setSubgroupProjects(fullPath, entry) {
      this.subgroupProjects = { ...this.subgroupProjects, [fullPath]: entry };
    },
    async loadSubgroupProjects(fullPath, after = null) {
      const loaded = this.subgroupProjects[fullPath] ?? {};

      this.setSubgroupProjects(fullPath, {
        projects: null,
        pageInfo: null,
        ...loaded,
        isLoading: true,
      });

      try {
        const { data } = await this.$apollo.query({
          query: getSubgroupProjectsQuery,
          variables: { fullPath, after },
        });

        // A subgroup can go missing between the parent query and this one, which comes back
        // as a successful null rather than an error.
        const { nodes, pageInfo } = data.group?.projects ?? {};

        this.setSubgroupProjects(fullPath, {
          isLoading: false,
          projects: [...(loaded.projects ?? []), ...(nodes ?? [])],
          pageInfo: pageInfo ?? null,
        });
      } catch (error) {
        if (loaded.projects) {
          // The pages already listed still stand, so keep them and let the button retry.
          this.setSubgroupProjects(fullPath, { ...loaded, isLoading: false });
        } else {
          // Collapse and forget the row, so expanding it again retries the fetch.
          const { [fullPath]: failed, ...rest } = this.subgroupProjects;
          this.subgroupProjects = rest;
          this.expandedPaths = this.expandedPaths.filter((path) => path !== fullPath);
        }

        this.$emit('error', error);
        captureException(error);
      }
    },
    async loadTopLevelGroups(after = null) {
      this.isLoadingTopLevelGroups = true;

      try {
        const { data } = await this.$apollo.query({
          query: getTopLevelGroupsQuery,
          variables: { after },
        });

        const { nodes, pageInfo } = data.groups ?? {};

        this.topLevelGroups = [...this.topLevelGroups, ...(nodes ?? [])];
        this.topLevelGroupsPageInfo = pageInfo ?? null;
      } catch (error) {
        // The pages already listed still stand, so keep them and let the button retry.
        this.$emit('error', error);
        captureException(error);
      } finally {
        this.isLoadingTopLevelGroups = false;
      }
    },
    // The row's value is the only thing that says which list it extends, so read the group back
    // out of it. Empty for the row that extends the top-level list.
    onLoadMore(value) {
      const fullPath = value.slice(0, -LOAD_MORE_ITEM_SUFFIX.length);

      if (fullPath) {
        this.loadSubgroupProjects(fullPath, this.subgroupProjects[fullPath]?.pageInfo?.endCursor);
        return;
      }

      this.loadTopLevelGroups(this.topLevelGroupsPageInfo?.endCursor);
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
    :loading="isLoadingFirstPage"
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

      <scope-picker-item
        v-else
        v-bind="item"
        @toggle-expanded="toggleExpanded(item.value)"
        @load-more="onLoadMore(item.value)"
      />
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

/* 1.5x the listbox's 19.5rem default. Groups expand in place rather than into a second panel,
   so the default cap leaves too little room to see a group and its projects at once. */
.analytics-scope-picker .gl-new-dropdown-inner {
  max-height: 29.25rem;
}

/* `fluid-width` sizes the panel to its rows, between 15.5rem and 28.5rem, so switching to the
   shorter search rows visibly narrows it. Raising the floor to the ceiling holds the width
   steady while the rows change underneath. */
.analytics-scope-picker .gl-new-dropdown-panel-fluid-width {
  min-width: 28.5rem;
}
</style>
