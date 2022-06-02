<script>
import * as Sentry from '@sentry/browser';
import Tracking from '~/tracking';
import {
  i18n,
  STATE_OPEN,
  STATE_CLOSED,
  STATE_EVENT_CLOSE,
  STATE_EVENT_REOPEN,
  TRACKING_CATEGORY_SHOW,
} from '../constants';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
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
    async updateWorkItemState(newState) {
      const stateEventMap = {
        [STATE_OPEN]: STATE_EVENT_REOPEN,
        [STATE_CLOSED]: STATE_EVENT_CLOSE,
      };

      const stateEvent = stateEventMap[newState];

      await this.updateWorkItem(stateEvent);
    },
    async updateWorkItem(updatedState) {
      if (!updatedState) {
        return;
      }

      this.updateInProgress = true;

      try {
        this.track('updated_state');

        const {
          data: { workItemUpdate },
        } = await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItem.id,
              stateEvent: updatedState,
            },
          },
        });

        if (workItemUpdate?.errors?.length) {
          throw new Error(workItemUpdate.errors[0]);
        }

        this.$emit('updated');
      } catch (error) {
        this.$emit('error', i18n.updateError);
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
    :loading="updateInProgress"
    @changed="updateWorkItemState"
  />
</template>
