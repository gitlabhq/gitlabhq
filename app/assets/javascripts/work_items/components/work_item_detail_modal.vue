<script>
import { GlAlert, GlModal } from '@gitlab/ui';
import WorkItemDetail from './work_item_detail.vue';

export default {
  components: {
    GlAlert,
    GlModal,
    WorkItemDetail,
  },
  props: {
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
  },
  emits: ['workItemDeleted', 'close'],
  data() {
    return {
      error: undefined,
    };
  },
  methods: {
    handleWorkItemDeleted() {
      this.$emit('workItemDeleted');
      this.closeModal();
    },
    closeModal() {
      this.error = '';
      this.$emit('close');
    },
    setErrorMessage(message) {
      this.error = message;
    },
    show() {
      this.$refs.modal.show();
    },
  },
};
</script>

<template>
  <gl-modal ref="modal" hide-footer size="lg" modal-id="work-item-detail-modal" @hide="closeModal">
    <gl-alert v-if="error" variant="danger" @dismiss="error = false">
      {{ error }}
    </gl-alert>

    <work-item-detail :work-item-id="workItemId" @workItemDeleted="handleWorkItemDeleted" />
  </gl-modal>
</template>

<style>
/* hide the existing modal header
 */
#work-item-detail-modal .modal-header {
  display: none;
}
</style>
