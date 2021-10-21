<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import { CONFIRM_DANGER_MODAL_ID } from './constants';
import ConfirmDangerModal from './confirm_danger_modal.vue';

export default {
  name: 'ConfirmDanger',
  components: {
    GlButton,
    ConfirmDangerModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    phrase: {
      type: String,
      required: true,
    },
    buttonText: {
      type: String,
      required: true,
    },
  },
  modalId: CONFIRM_DANGER_MODAL_ID,
};
</script>
<template>
  <div>
    <gl-button
      v-gl-modal="$options.modalId"
      class="gl-button"
      variant="danger"
      :disabled="disabled"
      data-testid="confirm-danger-button"
      >{{ buttonText }}</gl-button
    >
    <confirm-danger-modal
      :modal-id="$options.modalId"
      :phrase="phrase"
      @confirm="$emit('confirm')"
    />
  </div>
</template>
