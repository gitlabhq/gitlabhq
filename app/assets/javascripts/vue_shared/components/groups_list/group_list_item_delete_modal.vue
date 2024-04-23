<script>
import DangerConfirmModal from '~/vue_shared/components/confirm_danger/confirm_danger_modal.vue';

export default {
  name: 'GroupListItemDeleteModalCE',
  components: {
    DangerConfirmModal,
  },
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
    modalId: {
      type: String,
      required: true,
    },
    phrase: {
      type: String,
      required: true,
    },
    confirmLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <danger-confirm-modal
    v-if="visible"
    visible
    :modal-id="modalId"
    :phrase="phrase"
    :confirm-loading="confirmLoading"
    @confirm.prevent="$emit('confirm', $event)"
    @change="$emit('change', $event)"
  />
</template>
