<script>
import { GlButton, GlCollapsibleListbox } from '@gitlab/ui';
import { xor } from 'lodash-es';
import { s__ } from '~/locale';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import getGroupProjectsQuery from '../graphql/get_group_projects.query.graphql';
import ScopePickerItem from './scope_picker_item.vue';

export default {
  name: 'AnalyticsDashboardScopePicker',
  components: {
    GlButton,
    GlCollapsibleListbox,
    ScopePickerItem,
  },
  props: {
    groupFullPath: {
      type: String,
      required: true,
    },
  },
  emits: ['change', 'error'],
  data() {
    return {
      namespace: null,
      selectedPath: '',
      // The top-level group's projects arrive with the group itself, so it opens without a fetch.
      isExpanded: true,
    };
  },
  apollo: {
    namespace: {
      query: getGroupProjectsQuery,
      variables() {
        return { fullPath: this.groupFullPath };
      },
      update: ({ group }) => group,
      error(error) {
        this.$emit('error', error);
        captureException(error);
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.namespace.loading;
    },
    projects() {
      return this.namespace?.projects.nodes ?? [];
    },
    groupNamespace() {
      return this.namespace ? this.asNamespace(this.namespace) : null;
    },
    projectNamespaces() {
      return this.projects.map((project) => this.asNamespace(project));
    },
    selectedNamespace() {
      return (
        [this.groupNamespace, ...this.projectNamespaces].find(
          (namespace) => namespace?.fullPath === this.selectedPath,
        ) ?? null
      );
    },
    toggleText() {
      return this.selectedNamespace?.name ?? s__('AnalyticsDashboards|Select a group or project');
    },
    visibleItems() {
      if (!this.groupNamespace) return [];

      return [this.groupNamespace, ...(this.isExpanded ? this.projectNamespaces : [])].map(
        ({ name, fullPath, type }) => {
          const isGroup = type === TYPENAME_GROUP;
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
            expandable: isGroup && this.projects.length > 0,
            expanded: this.isExpanded,
            nested: !isGroup,
          };
        },
      );
    },
    selectedPaths() {
      return this.visibleItems.filter(({ selected }) => selected).map(({ value }) => value);
    },
  },
  methods: {
    asNamespace({ id, name, fullName, fullPath, __typename }) {
      return { id, name, fullName, fullPath, type: __typename };
    },
    hasSelectedDescendant(fullPath) {
      return this.selectedPath.startsWith(`${fullPath}/`);
    },
    onSelect(paths) {
      // The listbox reports the whole selection, but only one item can change per click and the
      // picker is single-select, so apply that item's toggle rather than taking the list as given.
      const [fullPath] = xor(paths, this.selectedPaths);

      // Ticking an item replaces the selection. Unticking it, or clearing an item left
      // indeterminate by a descendant, empties the selection instead.
      const clearsSelection =
        this.selectedPath === fullPath || this.hasSelectedDescendant(fullPath);

      this.selectedPath = clearsSelection ? '' : fullPath;

      this.$emit('change', this.selectedNamespace);
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
    :items="visibleItems"
    :selected="selectedPaths"
    :toggle-text="toggleText"
    :header-text="s__('AnalyticsDashboards|Scope')"
    :loading="isLoading"
    :searching="isLoading"
    @select="onSelect"
  >
    <template #list-item="{ item }">
      <scope-picker-item v-bind="item" @toggle-expanded="isExpanded = !isExpanded" />
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
