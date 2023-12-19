<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Tracking from '~/tracking';
import {
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_UPDATING,
  TRACKING_CATEGORY_SHOW,
  WORK_ITEM_TITLE_MAX_LENGTH,
  I18N_MAX_CHARS_IN_WORK_ITEM_TITLE_MESSAGE,
} from '../constants';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
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
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    useH1: {
      type: Boolean,
      default: false,
      required: false,
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

      if (updatedTitle.length > WORK_ITEM_TITLE_MAX_LENGTH) {
        this.$emit('error', sprintfWorkItem(I18N_MAX_CHARS_IN_WORK_ITEM_TITLE_MESSAGE));
        return;
      }

      this.updateInProgress = true;

      try {
        this.track('updated_title');

        const { data } = await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              title: updatedTitle,
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

      this.updateInProgress = false;
    },
  },
};
</script>

<template>
  <item-title
    :title="workItemTitle"
    :disabled="!canUpdate"
    :use-h1="useH1"
    @title-changed="updateTitle"
  />
</template>
