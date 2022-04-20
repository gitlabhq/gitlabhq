<script>
import { GlLoadingIcon } from '@gitlab/ui';
import Tracking from '~/tracking';
import { i18n } from '../constants';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import ItemTitle from './item_title.vue';

export default {
  components: {
    GlLoadingIcon,
    ItemTitle,
  },
  mixins: [Tracking.mixin()],
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
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
        category: 'workItems:show',
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
      } catch {
        this.$emit('error', i18n.updateError);
      }
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="loading" class="gl-mt-3" size="md" />
  <item-title v-else :title="workItemTitle" @title-changed="updateTitle" />
</template>
