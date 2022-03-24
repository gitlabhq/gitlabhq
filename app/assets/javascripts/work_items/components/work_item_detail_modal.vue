<script>
import { GlModal } from '@gitlab/ui';
import WorkItemDetail from './work_item_detail.vue';

export default {
  components: {
    GlModal,
    WorkItemDetail,
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <gl-modal hide-footer modal-id="work-item-detail-modal" :visible="visible" @hide="$emit('close')">
    <work-item-detail :work-item-id="workItemId" />
  </gl-modal>
</template>
