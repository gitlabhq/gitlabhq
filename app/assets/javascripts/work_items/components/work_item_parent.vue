<script>
import { GlIcon, GlLink, GlPopover } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__, sprintf } from '~/locale';
import WorkItemSidebarDropdownWidget from '~/work_items/components/shared/work_item_sidebar_dropdown_widget.vue';
import updateParentMutation from '~/work_items/graphql/update_parent.mutation.graphql';
import { isValidURL } from '~/lib/utils/url_utility';

import {
  findMilestoneWidget,
  findHierarchyWidgetDefinition,
  isReference,
  newWorkItemId,
} from '~/work_items/utils';
import { updateParent } from '../graphql/cache_utils';
import groupWorkItemsQuery from '../graphql/group_work_items.query.graphql';
import projectWorkItemsQuery from '../graphql/project_work_items.query.graphql';
import workItemsByReferencesQuery from '../graphql/work_items_by_references.query.graphql';
import workItemAllowedParentTypesQuery from '../graphql/work_item_allowed_parent_types.query.graphql';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  NAME_TO_ENUM_MAP,
  NAME_TO_TEXT_LOWERCASE_MAP,
  NO_WORK_ITEM_IID,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_ISSUE,
} from '../constants';

export default {
  linkId: uniqueId('work-item-parent-link-'),
  name: 'WorkItemParent',
  components: {
    GlLink,
    GlIcon,
    GlPopover,
    IssuePopover: () => import('~/issuable/popover/components/issue_popover.vue'),
    WorkItemSidebarDropdownWidget,
  },
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    fullPath: {
      required: true,
      type: String,
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
    allowedParentTypesForNewWorkItem: {
      type: Array,
      required: false,
      default: () => [],
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
      return this.workItemType === WORK_ITEM_TYPE_NAME_ISSUE;
    },
    isEpic() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_EPIC;
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
        s__('WorkItem|None')
      );
    },
    workItems() {
      return this.availableWorkItems?.map(({ id, title }) => ({ text: title, value: id })) || [];
    },
    parentWebUrl() {
      return this.parent?.webUrl;
    },
    visibleWorkItems() {
      return this.workItemsByReference.concat(this.workspaceWorkItems);
    },
    isSelectedParentAvailable() {
      return this.localSelectedItem && this.visibleWorkItems.length;
    },
    selectedParentMilestone() {
      const selectedParent = this.visibleWorkItems?.find(({ id }) => id === this.localSelectedItem);
      return findMilestoneWidget(selectedParent)?.milestone || null;
    },
    showCustomNoneValue() {
      return this.hasParent && this.parent === null;
    },
    isSearchingByReference() {
      return isReference(this.searchTerm) || isValidURL(this.searchTerm);
    },
    allowedParentTypesForNewWorkItemEnums() {
      return this.allowedParentTypesForNewWorkItem.map((type) => NAME_TO_ENUM_MAP[type.name]) || [];
    },
  },
  watch: {
    parent: {
      handler(newVal) {
        this.localSelectedItem = newVal?.id;
      },
    },
    localSelectedItem() {
      if (this.isEpic) this.handleSelectedParentMilestone();
    },
  },
  apollo: {
    workspaceWorkItems: {
      query() {
        // The logic to fetch the Parent seems to be different than other pages
        // Below issue targets to have a common logic across work items app
        // https://gitlab.com/gitlab-org/gitlab/-/issues/571302
        return this.isGroup || this.isIssue ? groupWorkItemsQuery : projectWorkItemsQuery;
      },
      variables() {
        // TODO: Remove the this.isIssue check once issues are migrated to work items
        return {
          fullPath: this.isIssue ? this.groupPath : this.fullPath,
          searchTerm: this.searchTerm,
          types: [...this.allowedParentTypes, ...this.allowedParentTypesForNewWorkItemEnums],
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
        return data.workspace?.workItems?.nodes?.filter((wi) => this.workItemId !== wi.id) || [];
      },
      error() {
        this.$emit(
          'error',
          s__('WorkItem|Something went wrong while fetching items. Please try again.'),
        );
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
        this.$emit(
          'error',
          s__('WorkItem|Something went wrong while fetching items. Please try again.'),
        );
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
            (el) => NAME_TO_ENUM_MAP[el.name],
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
      try {
        if (this.parent?.id === this.localSelectedItem) return;

        this.updateInProgress = true;

        if (this.workItemId === newWorkItemId(this.workItemType)) {
          this.$emit('updateWidgetDraft', {
            parent: this.isSelectedParentAvailable
              ? {
                  ...this.visibleWorkItems.find(({ id }) => id === this.localSelectedItem),
                }
              : null,
          });

          this.searchStarted = false;
          this.updateInProgress = false;
          return;
        }

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
                  this.localSelectedItem === NO_WORK_ITEM_IID ? null : this.localSelectedItem,
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
          this.localSelectedItem = this.parent?.id || NO_WORK_ITEM_IID;
        }
      } catch (error) {
        this.$emit(
          'error',
          sprintf(I18N_WORK_ITEM_ERROR_UPDATING, {
            workItemType: NAME_TO_TEXT_LOWERCASE_MAP[this.workItemType],
          }),
        );
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
      this.localSelectedItem = NO_WORK_ITEM_IID;
      this.updateParent();
    },
    onListboxShown() {
      this.searchStarted = true;
    },
    onListboxHide() {
      this.searchStarted = false;
      this.searchTerm = '';
    },
    handleSelectedParentMilestone() {
      this.$emit('parentMilestone', this.selectedParentMilestone);
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
    :header-text="s__('WorkItem|Select parent')"
    :update-in-progress="updateInProgress"
    :reset-button-label="s__('WorkItem|Clear')"
    :toggle-dropdown-text="listboxText"
    :search-placeholder="s__('WorkItem|Search or enter URL')"
    data-testid="work-item-parent"
    @dropdownShown="onListboxShown"
    @dropdownHidden="onListboxHide"
    @searchStarted="searchWorkItems"
    @updateValue="handleItemClick"
    @reset="unassignParent"
  >
    <template #readonly>
      <template v-if="localSelectedItem">
        <gl-link
          :id="$options.linkId"
          data-testid="work-item-parent-link"
          class="gl-inline-block gl-max-w-full gl-overflow-hidden gl-text-ellipsis gl-whitespace-nowrap gl-align-top gl-text-default"
          :href="parentWebUrl"
          >{{ listboxText }}</gl-link
        >
        <issue-popover
          v-if="parent"
          :cached-title="parent.title"
          :iid="parent.iid"
          :namespace-path="parent.namespace.fullPath"
          :target="$options.linkId"
        />
      </template>
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
