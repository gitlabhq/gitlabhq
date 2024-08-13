<script>
import { GlLink, GlDrawer } from '@gitlab/ui';
import deleteWorkItemMutation from '~/work_items/graphql/delete_work_item.mutation.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

export default {
  name: 'WorkItemDrawer',
  components: {
    GlLink,
    GlDrawer,
    WorkItemDetail: () => import('~/work_items/components/work_item_detail.vue'),
  },
  inheritAttrs: false,
  props: {
    open: {
      type: Boolean,
      required: true,
    },
    activeItem: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  methods: {
    async deleteWorkItem({ workItemId }) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: deleteWorkItemMutation,
          variables: { input: { id: workItemId } },
        });
        if (data.workItemDelete.errors?.length) {
          throw new Error(data.workItemDelete.errors[0]);
        }
        this.$emit('workItemDeleted');
      } catch (error) {
        this.$emit('deleteWorkItemError');
        Sentry.captureException(error);
      }
    },
  },
};
</script>

<template>
  <gl-drawer
    :open="open"
    data-testid="work-item-drawer"
    header-height="calc(var(--top-bar-height) + var(--performance-bar-height))"
    class="gl-w-full gl-sm-w-40p gl-leading-reset"
    @close="$emit('close')"
  >
    <template #title>
      <gl-link :href="activeItem.webUrl" class="gl-text-black-normal">{{
        __('Open full view')
      }}</gl-link>
    </template>
    <template #default>
      <work-item-detail
        :key="activeItem.iid"
        :work-item-iid="activeItem.iid"
        is-drawer
        class="gl-pt-0! work-item-drawer"
        @deleteWorkItem="deleteWorkItem"
        v-on="$listeners"
      />
    </template>
  </gl-drawer>
</template>
