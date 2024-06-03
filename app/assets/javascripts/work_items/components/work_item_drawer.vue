<script>
import { GlLink, GlDrawer } from '@gitlab/ui';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';

export default {
  name: 'WorkItemDrawer',
  components: {
    GlLink,
    GlDrawer,
    WorkItemDetail,
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
};
</script>

<template>
  <gl-drawer
    :open="open"
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
        v-on="$listeners"
      />
    </template>
  </gl-drawer>
</template>
