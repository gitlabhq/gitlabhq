<script>
import Tracking from '~/tracking';
import { i18n, TRACKING_CATEGORY_SHOW } from '../constants';
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

      try {
        await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              title: updatedTitle,
            },
          },
        });
        this.track('updated_title');
        this.$emit('updated');
      } catch {
        this.$emit('error', i18n.updateError);
      }
    },
  },
};
</script>

<template>
  <item-title :title="workItemTitle" @title-changed="updateTitle" />
</template>
