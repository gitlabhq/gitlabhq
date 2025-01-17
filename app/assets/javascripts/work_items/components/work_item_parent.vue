<script>
import { GlLink, GlIcon, GlPopover } from '@gitlab/ui';

import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import WorkItemSidebarDropdownWidget from '~/work_items/components/shared/work_item_sidebar_dropdown_widget.vue';
import updateParentMutation from '~/work_items/graphql/update_parent.mutation.graphql';
import { isValidURL } from '~/lib/utils/url_utility';

import updateNewWorkItemMutation from '~/work_items/graphql/update_new_work_item.mutation.graphql';
import { updateParent } from '../graphql/cache_utils';
import groupWorkItemsQuery from '../graphql/group_work_items.query.graphql';
import projectWorkItemsQuery from '../graphql/project_work_items.query.graphql';
import workItemsByReferencesQuery from '../graphql/work_items_by_references.query.graphql';
import workItemAllowedParentTypesQuery from '../graphql/work_item_allowed_parent_types.query.graphql';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  sprintfWorkItem,
  WORK_ITEM_TYPE_ENUM_EPIC,
  WORK_ITEM_TYPE_VALUE_ISSUE,
  WORK_ITEM_TYPE_VALUE_MAP,
} from '../constants';
import { isReference, findHierarchyWidgetDefinition, newWorkItemId } from '../utils';

export default {
  name: 'WorkItemParent',
  inputId: 'work-item-parent-listbox-value',
  noWorkItemId: 'no-work-item-id',
  i18n: {
    assignParentLabel: s__('WorkItem|Select parent'),
    parentLabel: s__('WorkItem|Parent'),
    none: s__('WorkItem|None'),
    unAssign: s__('WorkItem|Clear'),
    workItemsFetchError: s__(
      'WorkItem|Something went wrong while fetching items. Please try again.',
    ),
  },
  components: {
    GlLink,
    GlIcon,
    GlPopover,
    WorkItemSidebarDropdownWidget,
  },
  inject: ['fullPath'],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    parent: {
      type: Object,
      required: false,
      default: null,
    },
    workItemType: {
      type: String,
      required: false,
      default: '',
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    groupPath: {
      type: String,
      required: false,
      default: '',
    },
    hasParent: {
      type: Boolean,
      required: false,
      default: false,
    },
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      searchTerm: '',
      updateInProgress: false,
      searchStarted: false,
      localSelectedItem: this.parent?.id,
      oldParent: this.parent,
      workspaceWorkItems: [],
      workItemsByReference: [],
      allowedParentTypes: [],
    };
  },
  computed: {
    isIssue() {
      return this.workItemType === WORK_ITEM_TYPE_VALUE_ISSUE;
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
    listboxText() {
      return (
        this.workItems.find(({ value }) => this.localSelectedItem === value)?.text ||
        this.parent?.title ||
        this.$options.i18n.none
      );
    },
    workItems() {
      return this.availableWorkItems?.map(({ id, title }) => ({ text: title, value: id })) || [];
    },
    parentWebUrl() {
      return this.parent?.webUrl;
    },
    showCustomNoneValue() {
      return this.hasParent && this.parent === null;
    },
    isSearchingByReference() {
      return isReference(this.searchTerm) || isValidURL(this.searchTerm);
    },
    allowedParentTypesForNewWorkItem() {
      return this.workItemId === newWorkItemId(this.workItemType) ? [WORK_ITEM_TYPE_ENUM_EPIC] : [];
    },
  },
  watch: {
    parent: {
      handler(newVal) {
        this.localSelectedItem = newVal?.id;
      },
    },
  },
  apollo: {
    workspaceWorkItems: {
      query() {
        // TODO: Remove the this.isIssue check once issues are migrated to work items
        return this.isGroup || this.isIssue ? groupWorkItemsQuery : projectWorkItemsQuery;
      },
      variables() {
        // TODO: Remove the this.isIssue check once issues are migrated to work items
        return {
          fullPath: this.isIssue ? this.groupPath : this.fullPath,
          searchTerm: this.searchTerm,
          types: [...this.allowedParentTypes, ...this.allowedParentTypesForNewWorkItem],
          in: this.searchTerm ? 'TITLE' : undefined,
          iid: null,
          isNumber: false,
          includeAncestors: true,
        };
      },
      skip() {
        return !this.searchStarted && !this.allowedChildTypes?.length;
      },
      update(data) {
        return data.workspace.workItems.nodes.filter((wi) => this.workItemId !== wi.id) || [];
      },
      error() {
        this.$emit('error', this.$options.i18n.workItemsFetchError);
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
      error() {
        this.$emit('error', this.$options.i18n.workItemsFetchError);
      },
    },
    allowedParentTypes: {
      query: workItemAllowedParentTypesQuery,
      variables() {
        return {
          id: this.workItemId,
        };
      },
      skip() {
        return this.workItemId === newWorkItemId(this.workItemType);
      },
      update(data) {
        return (
          findHierarchyWidgetDefinition(data.workItem)?.allowedParentTypes?.nodes.map(
            (el) => WORK_ITEM_TYPE_VALUE_MAP[el.name],
          ) || []
        );
      },
    },
  },
  methods: {
    searchWorkItems(value) {
      this.searchTerm = value;
      this.searchStarted = true;
    },
    async updateParent() {
      if (this.parent?.id === this.localSelectedItem) return;

      this.updateInProgress = true;

      if (this.workItemId === newWorkItemId(this.workItemType)) {
        this.$apollo
          .mutate({
            mutation: updateNewWorkItemMutation,
            variables: {
              input: {
                fullPath: this.fullPath,
                parent: this.localSelectedItem
                  ? {
                      ...this.availableWorkItems?.find(({ id }) => id === this.localSelectedItem),
                      webUrl: this.parentWebUrl ?? null,
                    }
                  : null,
                workItemType: this.workItemType,
              },
            },
          })
          .catch((error) => {
            Sentry.captureException(error);
          })
          .finally(() => {
            this.searchStarted = false;
            this.updateInProgress = false;
          });
        return;
      }

      try {
        const {
          data: {
            workItemUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updateParentMutation,
          variables: {
            input: {
              id: this.workItemId,
              hierarchyWidget: {
                parentId:
                  this.localSelectedItem === this.$options.noWorkItemId
                    ? null
                    : this.localSelectedItem,
              },
            },
          },
          update: (cache) =>
            updateParent({
              cache,
              fullPath: this.fullPath,
              iid: this.oldParent?.iid,
              workItem: { id: this.workItemId },
            }),
        });

        if (errors.length) {
          this.$emit('error', errors.join('\n'));
          this.localSelectedItem = this.parent?.id || this.$options.noWorkItemId;
        }
      } catch (error) {
        this.$emit('error', sprintfWorkItem(I18N_WORK_ITEM_ERROR_UPDATING, this.workItemType));
        Sentry.captureException(error);
      } finally {
        this.searchStarted = false;
        this.updateInProgress = false;
      }
    },
    handleItemClick(item) {
      this.localSelectedItem = item;
      this.searchStarted = false;
      this.searchTerm = '';
      this.updateParent();
    },
    unassignParent() {
      this.localSelectedItem = this.$options.noWorkItemId;
      this.updateParent();
    },
    onListboxShown() {
      this.searchStarted = true;
    },
    onListboxHide() {
      this.searchStarted = false;
      this.searchTerm = '';
    },
  },
};
</script>

<template>
  <work-item-sidebar-dropdown-widget
    :dropdown-label="__('Parent')"
    :can-update="canUpdate"
    dropdown-name="parent"
    :list-items="workItems"
    :loading="isLoading"
    :item-value="localSelectedItem"
    :header-text="$options.i18n.assignParentLabel"
    :update-in-progress="updateInProgress"
    :reset-button-label="$options.i18n.unAssign"
    :toggle-dropdown-text="listboxText"
    data-testid="work-item-parent"
    @dropdownShown="onListboxShown"
    @dropdownHidden="onListboxHide"
    @searchStarted="searchWorkItems"
    @updateValue="handleItemClick"
    @reset="unassignParent"
  >
    <template #readonly>
      <gl-link
        v-if="localSelectedItem"
        data-testid="work-item-parent-link"
        class="gl-inline-block gl-max-w-full gl-overflow-hidden gl-text-ellipsis gl-whitespace-nowrap gl-align-top gl-text-default"
        :href="parentWebUrl"
        >{{ listboxText }}</gl-link
      >
    </template>
    <template v-if="showCustomNoneValue" #none>
      <span id="parent-not-available" class="gl-cursor-help">
        <gl-popover triggers="hover focus" placement="bottom" :target="'parent-not-available'">
          <span>{{
            s__(`WorkItem|You don't have the necessary permission to view the ancestor.`)
          }}</span>
        </gl-popover>
        <gl-icon name="eye-slash" class="gl-mr-2" variant="subtle" />
        <span data-testid="ancestor-not-available">{{
          s__('WorkItem|Ancestor not available')
        }}</span></span
      >
    </template>
  </work-item-sidebar-dropdown-widget>
</template>
