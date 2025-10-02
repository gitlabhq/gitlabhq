<script>
import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { debounce, unionBy } from 'lodash';
import { createAlert } from '~/alert';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __, s__ } from '~/locale';
import { isValidURL } from '~/lib/utils/url_utility';
import {
  BULK_EDIT_NO_VALUE,
  NAME_TO_ENUM_MAP,
  WORK_ITEM_TYPE_ENUM_EPIC,
  WORK_ITEMS_NO_PARENT_LIST,
} from '../../constants';
import groupWorkItemsQuery from '../../graphql/group_work_items.query.graphql';
import projectWorkItemsQuery from '../../graphql/project_work_items.query.graphql';
import workItemsByReferencesQuery from '../../graphql/work_items_by_references.query.graphql';
import namespaceWorkItemTypesQuery from '../../graphql/namespace_work_item_types.query.graphql';
import { isReference, findHierarchyWidgetDefinition } from '../../utils';

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
    selectedWorkItemTypesIds: {
      type: Array,
      required: false,
      default: () => [],
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
      allowedParentTypesMap: {},
    };
  },
  apollo: {
    workspaceWorkItems: {
      query() {
        // The logic to fetch the Parent seems to be different than other pages
        // Below issue targets to have a common logic across work items app
        // https://gitlab.com/gitlab-org/gitlab/-/issues/571302
        return this.shouldSearchAcrossGroups ? groupWorkItemsQuery : projectWorkItemsQuery;
      },
      variables() {
        return {
          fullPath: !this.isGroup && this.shouldSearchAcrossGroups ? this.groupPath : this.fullPath,
          searchTerm: this.searchTerm,
          in: this.searchTerm ? 'TITLE' : undefined,
          includeAncestors: true,
          includeDescendants: this.shouldSearchAcrossGroups,
          types: this.selectedItemParentTypes.filter(
            (type) => !WORK_ITEMS_NO_PARENT_LIST.includes(type),
          ),
        };
      },
      skip() {
        return !this.searchStarted || !this.shouldLoadParents;
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
    allowedParentTypesMap: {
      query: namespaceWorkItemTypesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        const typesParentsMap = {};
        const types = data.workspace.workItemTypes.nodes || [];

        // Used `for` loop for better readability and performance
        for (const type of types) {
          // Get the hierarchy widgets
          const hierarchyWidget = findHierarchyWidgetDefinition({ workItemType: type });

          // If there are allowed parent types map the ids and names
          if (hierarchyWidget?.allowedParentTypes?.nodes?.length > 0) {
            const parentNames = hierarchyWidget.allowedParentTypes?.nodes.map((parent) => {
              // Used enums because the workspaceWorkItems does not support gids in the types fields
              return { id: parent.id, name: NAME_TO_ENUM_MAP[parent.name] };
            });
            typesParentsMap[type.id] = parentNames;
          }
        }

        return typesParentsMap;
      },
      skip() {
        return !this.fullPath;
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
      if (!this.shouldLoadParents) {
        return [];
      }

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
    selectedItemsCanHaveParents() {
      return this.selectedWorkItemTypesIds.some((id) =>
        Object.keys(this.allowedParentTypesMap).includes(id),
      );
    },
    areTypesCompatible() {
      return (
        this.selectedWorkItemTypesIds
          .map((id) => new Set((this.allowedParentTypesMap[id] || []).map((type) => type.id)))
          .reduce((intersection, parentIds) => {
            // If there are no parents
            if (parentIds.size === 0) return new Set();
            // If parents are unique
            if (!intersection) return parentIds;
            // Verify if the parents are incompatible
            return new Set([...parentIds].filter((id) => intersection.has(id)));
          }, null)?.size > 0 ?? false
      );
    },
    shouldLoadParents() {
      return this.selectedItemsCanHaveParents && this.areTypesCompatible;
    },
    selectedItemParentTypes() {
      return [
        ...new Set(
          this.selectedWorkItemTypesIds?.flatMap(
            (id) => this.allowedParentTypesMap?.[id]?.map((type) => type.name) || [],
          ),
        ),
      ];
    },
    canHaveEpicParent() {
      return this.selectedItemParentTypes?.includes(WORK_ITEM_TYPE_ENUM_EPIC);
    },
    shouldSearchAcrossGroups() {
      // Determines if we need to search across groups.
      // Cross-group search applies only when the parent is
      // a group-level work item, an epic.
      return this.isGroup || this.canHaveEpicParent;
    },
    groupPath() {
      return this.fullPath.substring(0, this.fullPath.lastIndexOf('/'));
    },
    noResultText() {
      return !this.shouldLoadParents
        ? s__('WorkItem|No available parent for all selected items.')
        : s__('WorkItem|No matching results');
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
      :no-results-text="noResultText"
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
