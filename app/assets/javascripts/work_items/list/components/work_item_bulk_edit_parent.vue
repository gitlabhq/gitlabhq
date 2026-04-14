<script>
import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { debounce, unionBy, uniqueId } from 'lodash-es';
import { createAlert } from '~/alert';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __, s__ } from '~/locale';
import { isValidURL } from '~/lib/utils/url_utility';
import { BULK_EDIT_NO_VALUE, NAME_TO_ENUM_MAP } from '~/work_items/constants';
import groupWorkItemsQuery from '~/work_items/graphql/group_work_items.query.graphql';
import projectWorkItemsQuery from '~/work_items/graphql/project_work_items.query.graphql';
import workItemsByReferencesQuery from '~/work_items/graphql/work_items_by_references.query.graphql';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import { isReference, findHierarchyWidgetDefinition } from '~/work_items/utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'WorkItemBulkEditParent',
  components: {
    GlCollapsibleListbox,
    GlFormGroup,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['workItemTypesConfiguration'],
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
  emits: ['input'],
  data() {
    return {
      parentToggleId: uniqueId('wi-parent-toggle-'),
      searchStarted: false,
      searchTerm: '',
      selectedId: this.value,
      namespaceWorkItems: [],
      workItemsCache: [],
      workItemsByReference: [],
      allowedParentTypesMap: {},
    };
  },
  apollo: {
    namespaceWorkItems: {
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
          ...(this.glFeatures.workItemConfigurableTypes
            ? {
                workItemTypeIds: this.selectedItemParentTypes.map((type) => type.id),
              }
            : {
                types: this.selectedItemParentTypes.map((type) => NAME_TO_ENUM_MAP[type.name]),
              }),
        };
      },
      skip() {
        return !this.searchStarted || !this.shouldLoadParents;
      },
      update(data) {
        return data.namespace?.workItems?.nodes || [];
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
        const types = data.namespace.workItemTypes.nodes || [];

        // Used `for` loop for better readability and performance
        for (const type of types) {
          // Get the hierarchy widgets
          const hierarchyWidget = findHierarchyWidgetDefinition({ workItemType: type });

          // If there are allowed parent types map the ids and names
          if (hierarchyWidget?.allowedParentTypes?.nodes?.length > 0) {
            typesParentsMap[type.id] = hierarchyWidget.allowedParentTypes?.nodes;
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
        this.$apollo.queries.namespaceWorkItems.loading ||
        this.$apollo.queries.workItemsByReference.loading
      );
    },
    availableWorkItems() {
      return this.isSearchingByReference ? this.workItemsByReference : this.namespaceWorkItems;
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
          this.selectedWorkItemTypesIds?.flatMap((id) => this.allowedParentTypesMap?.[id] || []),
        ),
      ];
    },
    canHaveEpicParent() {
      return this.selectedItemParentTypes?.some(({ id }) => {
        return this.workItemTypesConfiguration.find((type) => type.id === id)?.isGroupWorkItemType;
      });
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
    namespaceWorkItems(namespaceWorkItems) {
      this.updateWorkItemsCache(namespaceWorkItems);
    },
    workItemsByReference(workItemsByReference) {
      this.updateWorkItemsCache(workItemsByReference);
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
    updateWorkItemsCache(namespaceWorkItems) {
      // Need to store all namespaceWorkItems we encounter so we can show "Selected"
      // namespaceWorkItems even if they're not found in the apollo `namespaceWorkItems` list
      this.workItemsCache = unionBy(this.workItemsCache, namespaceWorkItems, 'id');
    },
  },
};
</script>

<template>
  <gl-form-group :label="__('Parent')" :label-for="parentToggleId">
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
      :toggle-id="parentToggleId"
      :toggle-text="toggleText"
      :disabled="disabled"
      @reset="reset"
      @search="setSearchTermDebounced"
      @select="handleSelect"
      @shown="handleShown"
    />
  </gl-form-group>
</template>
