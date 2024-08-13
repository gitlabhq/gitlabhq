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
  WIDGET_TYPE_LINKED_ITEMS,
  LINKED_CATEGORIES_MAP,
  i18n,
} from '../constants';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';

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
  },
  data() {
    return {
      updateInProgress: false,
      blockers: [],
    };
  },
  apollo: {
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
      async result() {
        this.blockers = this.linkedWorkItems.filter((item) => {
          return item.linkType === LINKED_CATEGORIES_MAP.IS_BLOCKED_BY;
        });
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
      return this.blockers.length > 0;
    },
    action() {
      if (this.isBlocked && this.isWorkItemOpen) {
        return () => this.$refs.blockedByIssuesModal.show();
      }
      return this.updateWorkItem;
    },
    linkedWorkItemsWidget() {
      return this.workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_LINKED_ITEMS);
    },
    linkedWorkItems() {
      return this.linkedWorkItemsWidget?.linkedItems?.nodes || [];
    },
    modalTitle() {
      return sprintfWorkItem(
        s__('WorkItem|Are you sure you want to close this blocked %{workItemType}?'),
        this.workItemType,
      );
    },
    modalBody() {
      return sprintfWorkItem(
        s__('WorkItem|This %{workItemType} is currently blocked by the following items:'),
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

    <gl-button v-else :loading="updateInProgress" @click="action">{{
      toggleWorkItemStateText
    }}</gl-button>

    <gl-modal
      ref="blockedByIssuesModal"
      modal-id="blocked-by-issues-modal"
      :action-cancel="modalActionCancel"
      :action-primary="modalActionPrimary"
      :title="modalTitle"
      @primary="updateWorkItem"
    >
      <p>{{ modalBody }}</p>
      <ul>
        <li v-for="issue in blockers" :key="issue.workItem.iid">
          <gl-link :href="issue.workItem.webUrl">#{{ issue.workItem.iid }}</gl-link>
        </li>
      </ul>
    </gl-modal>
  </span>
</template>
