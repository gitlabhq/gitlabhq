<script>
import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { debounce, unionBy } from 'lodash';
import { createAlert } from '~/alert';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __, s__ } from '~/locale';
import { isValidURL } from '~/lib/utils/url_utility';
import { BULK_EDIT_NO_VALUE } from '../../constants';
import groupWorkItemsQuery from '../../graphql/group_work_items.query.graphql';
import projectWorkItemsQuery from '../../graphql/project_work_items.query.graphql';
import workItemsByReferencesQuery from '../../graphql/work_items_by_references.query.graphql';
import { isReference } from '../../utils';

export default {
  components: {
    GlCollapsibleListbox,
    GlFormGroup,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    value: {
      type: String,
      required: false,
      default: undefined,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      searchStarted: false,
      searchTerm: '',
      selectedId: this.value,
      workspaceWorkItems: [],
      workItemsCache: [],
      workItemsByReference: [],
    };
  },
  apollo: {
    workspaceWorkItems: {
      query() {
        return this.isGroup ? groupWorkItemsQuery : projectWorkItemsQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          searchTerm: this.searchTerm,
          in: this.searchTerm ? 'TITLE' : undefined,
          includeAncestors: true,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return data.workspace?.workItems?.nodes || [];
      },
      error(error) {
        createAlert({
          message: __('Failed to load work items. Please try again.'),
          captureError: true,
          error,
        });
      },
    },
    workItemsByReference: {
      query: workItemsByReferencesQuery,
      variables() {
        return {
          contextNamespacePath: this.fullPath,
          refs: [this.searchTerm],
        };
      },
      skip() {
        return !this.isSearchingByReference;
      },
      update(data) {
        return data?.workItemsByReference?.nodes || [];
      },
      error(error) {
        createAlert({
          message: __('Failed to load work items. Please try again.'),
          captureError: true,
          error,
        });
      },
    },
  },
  computed: {
    isSearchingByReference() {
      return isReference(this.searchTerm) || isValidURL(this.searchTerm);
    },
    isLoading() {
      return (
        this.$apollo.queries.workspaceWorkItems.loading ||
        this.$apollo.queries.workItemsByReference.loading
      );
    },
    availableWorkItems() {
      return this.isSearchingByReference ? this.workItemsByReference : this.workspaceWorkItems;
    },
    listboxItems() {
      if (!this.searchTerm.trim().length) {
        return [
          {
            text: s__('WorkItem|No parent'),
            textSrOnly: true,
            options: [{ text: s__('WorkItem|No parent'), value: BULK_EDIT_NO_VALUE }],
          },
          {
            text: __('All'),
            textSrOnly: true,
            options:
              this.availableWorkItems?.map(({ id, title }) => ({ text: title, value: id })) || [],
          },
        ];
      }

      return this.availableWorkItems?.map(({ id, title }) => ({ text: title, value: id })) || [];
    },
    selectedWorkItem() {
      return this.workItemsCache.find((workItem) => this.selectedId === workItem.id);
    },
    toggleText() {
      if (this.selectedWorkItem) {
        return this.selectedWorkItem.title;
      }
      if (this.selectedId === BULK_EDIT_NO_VALUE) {
        return s__('WorkItem|No parent');
      }
      return s__('WorkItem|Select parent');
    },
  },
  watch: {
    workspaceWorkItems(workspaceWorkItems) {
      this.updateWorkItemsCache(workspaceWorkItems);
    },
    workItemsByReference(workspaceWorkItems) {
      this.updateWorkItemsCache(workspaceWorkItems);
    },
  },
  created() {
    this.setSearchTermDebounced = debounce(this.setSearchTerm, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    clearSearch() {
      this.searchTerm = '';
      this.$refs.listbox.$refs.searchBox.clearInput?.();
    },
    handleSelect(item) {
      this.selectedId = item;
      this.$emit('input', item);
      this.clearSearch();
    },
    handleShown() {
      this.searchTerm = '';
      this.searchStarted = true;
    },
    reset() {
      this.handleSelect(undefined);
      this.$refs.listbox.close();
    },
    setSearchTerm(searchTerm) {
      this.searchTerm = searchTerm;
    },
    updateWorkItemsCache(workspaceWorkItems) {
      // Need to store all workspaceWorkItems we encounter so we can show "Selected" workspaceWorkItems
      // even if they're not found in the apollo `workspaceWorkItems` list
      this.workItemsCache = unionBy(this.workItemsCache, workspaceWorkItems, 'id');
    },
  },
};
</script>

<template>
  <gl-form-group :label="__('Parent')">
    <gl-collapsible-listbox
      ref="listbox"
      block
      :header-text="s__('WorkItem|Select parent')"
      is-check-centered
      :items="listboxItems"
      :no-results-text="s__('WorkItem|No matching results')"
      :reset-button-label="__('Reset')"
      searchable
      :searching="isLoading"
      :selected="selectedId"
      :toggle-text="toggleText"
      :disabled="disabled"
      @reset="reset"
      @search="setSearchTermDebounced"
      @select="handleSelect"
      @shown="handleShown"
    />
  </gl-form-group>
</template>
