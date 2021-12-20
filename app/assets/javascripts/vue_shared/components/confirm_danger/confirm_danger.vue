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
    buttonClass: {
      type: String,
      required: false,
      default: '',
    },
    buttonTestid: {
      type: String,
      required: false,
      default: 'confirm-danger-button',
    },
    buttonVariant: {
      type: String,
      required: false,
      default: 'danger',
    },
  },
  modalId: CONFIRM_DANGER_MODAL_ID,
};
</script>
<template>
  <div>
    <gl-button
      v-gl-modal="$options.modalId"
      :class="buttonClass"
      :variant="buttonVariant"
      :disabled="disabled"
      :data-testid="buttonTestid"
      >{{ buttonText }}</gl-button
    >
    <confirm-danger-modal
      :modal-id="$options.modalId"
      :phrase="phrase"
      @confirm="$emit('confirm')"
    />
  </div>
</template>
