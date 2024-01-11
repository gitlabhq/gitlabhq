<script>
import { GlButton, GlDisclosureDropdownItem, GlLoadingIcon } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Tracking from '~/tracking';
import { __ } from '~/locale';
import {
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_UPDATING,
  STATE_OPEN,
  STATE_EVENT_CLOSE,
  STATE_EVENT_REOPEN,
  TRACKING_CATEGORY_SHOW,
} from '../constants';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';

export default {
  components: {
    GlButton,
    GlDisclosureDropdownItem,
    GlLoadingIcon,
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
    workItemType: {
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
    };
  },
  computed: {
    isWorkItemOpen() {
      return this.workItemState === STATE_OPEN;
    },
    toggleWorkItemStateText() {
      let baseText = this.isWorkItemOpen
        ? __('Close %{workItemType}')
        : __('Reopen %{workItemType}');

      if (this.hasComment) {
        baseText = this.isWorkItemOpen
          ? __('Comment & close %{workItemType}')
          : __('Comment & reopen %{workItemType}');
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
        ? __('Closing %{workItemType}')
        : __('Reopening %{workItemType}');
      return sprintfWorkItem(baseText, this.workItemType);
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

      this.updateInProgress = false;
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item v-if="showAsDropdownItem" @action="updateWorkItem">
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
  <gl-button v-else :loading="updateInProgress" @click="updateWorkItem">{{
    toggleWorkItemStateText
  }}</gl-button>
</template>
