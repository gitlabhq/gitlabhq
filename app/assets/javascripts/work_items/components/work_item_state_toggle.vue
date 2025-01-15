<script>
import { GlButton, GlDisclosureDropdownItem, GlLoadingIcon, GlModal, GlLink } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Tracking from '~/tracking';
import { __, s__ } from '~/locale';
import {
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_UPDATING,
  STATE_OPEN,
  STATE_EVENT_CLOSE,
  STATE_EVENT_REOPEN,
  TRACKING_CATEGORY_SHOW,
  LINKED_CATEGORIES_MAP,
  i18n,
} from '../constants';
import { findHierarchyWidgets, findLinkedItemsWidget } from '../utils';
import { updateCountsForParent } from '../graphql/cache_utils';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import workItemLinkedItemsQuery from '../graphql/work_item_linked_items.query.graphql';
import workItemOpenChildCountQuery from '../graphql/open_child_count.query.graphql';

export default {
  components: {
    GlButton,
    GlDisclosureDropdownItem,
    GlLoadingIcon,
    GlModal,
    GlLink,
  },
  mixins: [Tracking.mixin()],
  props: {
    workItemState: {
      type: String,
      required: true,
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    showAsDropdownItem: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasComment: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    parentId: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      updateInProgress: false,
      blockerItems: [],
      openChildItemsCount: 0,
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data.workspace.workItem ?? {};
      },
      skip() {
        return !this.workItemIid;
      },
      error(e) {
        const msg = e.message || i18n.fetchError;
        this.$emit('error', msg);
        Sentry.captureException(new Error(msg));
      },
    },
    blockerItems: {
      query: workItemLinkedItemsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      skip() {
        return !this.workItemIid;
      },
      update({ workspace }) {
        if (!workspace?.workItem) return [];

        const linkedWorkItems = findLinkedItemsWidget(workspace.workItem)?.linkedItems?.nodes || [];

        return linkedWorkItems.filter((item) => {
          return item.linkType === LINKED_CATEGORIES_MAP.IS_BLOCKED_BY;
        });
      },
      error(e) {
        const msg = e.message || i18n.fetchError;
        this.$emit('error', msg);
        Sentry.captureException(new Error(msg));
      },
    },
    openChildItemsCount: {
      query: workItemOpenChildCountQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      skip() {
        return !this.workItemIid;
      },
      update({ namespace }) {
        if (!namespace?.workItem) return 0;

        /** @type {Array<{countsByState: { opened : number }}> } */
        const countsByType = findHierarchyWidgets(namespace.workItem.widgets)?.rolledUpCountsByType;

        if (!countsByType) {
          return 0;
        }

        const total = countsByType.reduce((acc, curr) => acc + curr.countsByState.opened, 0);

        return total;
      },
    },
  },
  computed: {
    isWorkItemOpen() {
      return this.workItemState === STATE_OPEN;
    },
    toggleWorkItemStateText() {
      let baseText = this.isWorkItemOpen
        ? s__('WorkItem|Close %{workItemType}')
        : s__('WorkItem|Reopen %{workItemType}');

      if (this.hasComment) {
        baseText = this.isWorkItemOpen
          ? s__('WorkItem|Comment & close %{workItemType}')
          : s__('WorkItem|Comment & reopen %{workItemType}');
      }
      return sprintfWorkItem(baseText, this.workItemType);
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_state',
        property: `type_${this.workItemType}`,
      };
    },
    toggleInProgressText() {
      const baseText = this.isWorkItemOpen
        ? s__('WorkItem|Closing %{workItemType}')
        : s__('WorkItem|Reopening %{workItemType}');
      return sprintfWorkItem(baseText, this.workItemType);
    },
    isBlocked() {
      return this.blockerItems.length > 0;
    },
    hasOpenChildren() {
      return this.openChildItemsCount > 0;
    },
    action() {
      if (this.isWorkItemOpen) {
        if (this.isBlocked) {
          return () => this.$refs.blockedByIssuesModal.show();
        }
        if (this.hasOpenChildren) {
          return () => this.$refs.openChildrenWarningModal.show();
        }
      }
      return this.updateWorkItem;
    },
    blockedByModalTitle() {
      return sprintfWorkItem(
        s__('WorkItem|Are you sure you want to close this blocked %{workItemType}?'),
        this.workItemType,
      );
    },
    blockedByModalBody() {
      return sprintfWorkItem(
        s__('WorkItem|This %{workItemType} is currently blocked by the following items:'),
        this.workItemType,
      );
    },
    openChildrenModalTitle() {
      return sprintfWorkItem(
        s__('WorkItem|Are you sure you want to close this %{workItemType}?'),
        this.workItemType,
      );
    },
    openChildrenModalBody() {
      return sprintfWorkItem(
        s__(
          'WorkItem|This %{workItemType} has open child items. If you close this %{workItemType}, they will remain open.',
        ),
        this.workItemType,
      );
    },
    modalActionCancel() {
      return {
        text: __('Cancel'),
      };
    },
    modalActionPrimary() {
      return {
        text: sprintfWorkItem(s__('WorkItem|Yes, close %{workItemType}'), this.workItemType),
      };
    },
  },
  methods: {
    async updateWorkItem() {
      this.updateInProgress = true;

      try {
        this.track('updated_state');

        const { data } = await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              stateEvent: this.isWorkItemOpen ? STATE_EVENT_CLOSE : STATE_EVENT_REOPEN,
            },
          },
          update: (cache) =>
            updateCountsForParent({
              cache,
              parentId: this.parentId,
              workItemType: this.workItemType,
              isClosing: this.isWorkItemOpen,
            }),
        });

        const errors = data.workItemUpdate?.errors;

        if (errors?.length) {
          throw new Error(errors[0]);
        }
      } catch (error) {
        const msg = sprintfWorkItem(I18N_WORK_ITEM_ERROR_UPDATING, this.workItemType);
        this.$emit('error', msg);
        Sentry.captureException(error);
      }

      if (this.hasComment) {
        this.$emit('submit-comment');
      }
      this.$emit('workItemStateUpdated');

      this.updateInProgress = false;
    },
  },
};
</script>

<template>
  <span>
    <gl-disclosure-dropdown-item v-if="showAsDropdownItem" @action="action">
      <template #list-item>
        <template v-if="updateInProgress">
          <gl-loading-icon inline size="sm" />
          {{ toggleInProgressText }}
        </template>
        <template v-else>
          {{ toggleWorkItemStateText }}
        </template>
      </template>
    </gl-disclosure-dropdown-item>

    <gl-button v-else :loading="updateInProgress" :disabled="disabled" @click="action">{{
      toggleWorkItemStateText
    }}</gl-button>

    <gl-modal
      ref="blockedByIssuesModal"
      modal-id="blocked-by-issues-modal"
      data-testid="blocked-by-issues-modal"
      :action-cancel="modalActionCancel"
      :action-primary="modalActionPrimary"
      :title="blockedByModalTitle"
      @primary="updateWorkItem"
    >
      <p>{{ blockedByModalBody }}</p>
      <ul>
        <li v-for="issue in blockerItems" :key="issue.workItem.iid">
          <gl-link :href="issue.workItem.webUrl">#{{ issue.workItem.iid }}</gl-link>
        </li>
      </ul>
    </gl-modal>

    <gl-modal
      ref="openChildrenWarningModal"
      modal-id="open-children-warning-modal"
      data-testid="open-children-warning-modal"
      :action-cancel="modalActionCancel"
      :action-primary="modalActionPrimary"
      :title="openChildrenModalTitle"
      @primary="updateWorkItem"
    >
      <p>{{ openChildrenModalBody }}</p>
    </gl-modal>
  </span>
</template>
