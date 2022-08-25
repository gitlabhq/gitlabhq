<script>
import * as Sentry from '@sentry/browser';
import Tracking from '~/tracking';
import {
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_UPDATING,
  STATE_OPEN,
  STATE_CLOSED,
  STATE_EVENT_CLOSE,
  STATE_EVENT_REOPEN,
  TRACKING_CATEGORY_SHOW,
} from '../constants';
import { getUpdateWorkItemMutation } from './update_work_item';
import ItemState from './item_state.vue';

export default {
  components: {
    ItemState,
  },
  mixins: [Tracking.mixin()],
  props: {
    workItem: {
      type: Object,
      required: true,
    },
    workItemParentId: {
      type: String,
      required: false,
      default: null,
    },
    canUpdate: {
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
    workItemType() {
      return this.workItem.workItemType?.name;
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
    updateWorkItemState(newState) {
      const stateEventMap = {
        [STATE_OPEN]: STATE_EVENT_REOPEN,
        [STATE_CLOSED]: STATE_EVENT_CLOSE,
      };

      const stateEvent = stateEventMap[newState];

      this.updateWorkItem(stateEvent);
    },

    async updateWorkItem(updatedState) {
      if (!updatedState) {
        return;
      }

      const input = {
        id: this.workItem.id,
        stateEvent: updatedState,
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
  <item-state
    v-if="workItem.state"
    :state="workItem.state"
    :disabled="updateInProgress || !canUpdate"
    @changed="updateWorkItemState"
  />
</template>
