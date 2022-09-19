<script>
import * as Sentry from '@sentry/browser';
import Tracking from '~/tracking';
import {
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_UPDATING,
  TRACKING_CATEGORY_SHOW,
} from '../constants';
import { getUpdateWorkItemMutation } from './update_work_item';
import ItemTitle from './item_title.vue';

export default {
  components: {
    ItemTitle,
  },
  mixins: [Tracking.mixin()],
  props: {
    workItemId: {
      type: String,
      required: false,
      default: '',
    },
    workItemTitle: {
      type: String,
      required: false,
      default: '',
    },
    workItemType: {
      type: String,
      required: false,
      default: '',
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
  computed: {
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_title',
        property: `type_${this.workItemType}`,
      };
    },
  },
  methods: {
    async updateTitle(updatedTitle) {
      if (updatedTitle === this.workItemTitle) {
        return;
      }

      const input = {
        id: this.workItemId,
        title: updatedTitle,
      };

      this.updateInProgress = true;

      try {
        this.track('updated_title');

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
  <item-title :title="workItemTitle" :disabled="!canUpdate" @title-changed="updateTitle" />
</template>
