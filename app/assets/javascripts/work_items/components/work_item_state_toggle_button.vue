<script>
import { GlButton } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import Tracking from '~/tracking';
import { __, sprintf } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { getUpdateWorkItemMutation } from '~/work_items/components/update_work_item';
import {
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_UPDATING,
  STATE_OPEN,
  STATE_EVENT_CLOSE,
  STATE_EVENT_REOPEN,
  TRACKING_CATEGORY_SHOW,
} from '../constants';

export default {
  components: {
    GlButton,
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
    workItemParentId: {
      type: String,
      required: false,
      default: null,
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
      const baseText = this.isWorkItemOpen
        ? __('Close %{workItemType}')
        : __('Reopen %{workItemType}');
      return capitalizeFirstCharacter(
        sprintf(baseText, { workItemType: this.workItemType.toLowerCase() }),
      );
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_state',
        property: `type_${this.workItemType}`,
      };
    },
  },
  methods: {
    async updateWorkItem() {
      const input = {
        id: this.workItemId,
        stateEvent: this.isWorkItemOpen ? STATE_EVENT_CLOSE : STATE_EVENT_REOPEN,
      };

      this.updateInProgress = true;

      try {
        this.track('updated_state');

        const { mutation, variables } = getUpdateWorkItemMutation({
          workItemParentId: this.workItemParentId,
          input,
        });

        const { data } = await this.$apollo.mutate({
          mutation,
          variables,
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

      this.updateInProgress = false;
    },
  },
};
</script>

<template>
  <gl-button
    :loading="updateInProgress"
    data-testid="work-item-state-toggle"
    @click="updateWorkItem"
    >{{ toggleWorkItemStateText }}</gl-button
  >
</template>
