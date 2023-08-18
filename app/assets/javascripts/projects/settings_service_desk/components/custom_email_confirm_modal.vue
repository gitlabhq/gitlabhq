<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import {
  I18N_MODAL_TITLE,
  I18N_MODAL_CANCEL_BUTTON_LABEL,
  I18N_RESET_BUTTON_LABEL,
  I18N_MODAL_DISABLE_CUSTOM_EMAIL_PARAGRAPH,
  I18N_MODAL_SET_UP_AGAIN_PARAGRAPH,
} from '../custom_email_constants';

export default {
  components: {
    GlModal,
    GlSprintf,
  },
  I18N_MODAL_TITLE,
  I18N_RESET_BUTTON_LABEL,
  I18N_MODAL_DISABLE_CUSTOM_EMAIL_PARAGRAPH,
  I18N_MODAL_SET_UP_AGAIN_PARAGRAPH,
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    customEmail: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    primaryButtonAttributes() {
      return {
        text: I18N_RESET_BUTTON_LABEL,
        attributes: {
          variant: 'danger',
        },
      };
    },
    cancelButtonAttributes() {
      return {
        text: I18N_MODAL_CANCEL_BUTTON_LABEL,
      };
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="custom-email-confirm-modal"
    :title="$options.I18N_MODAL_TITLE"
    :action-primary="primaryButtonAttributes"
    :action-cancel="cancelButtonAttributes"
    :visible="visible"
    @primary="$emit('remove')"
    @canceled="$emit('cancel')"
    @hidden="$emit('cancel')"
  >
    <p>
      <gl-sprintf :message="$options.I18N_MODAL_DISABLE_CUSTOM_EMAIL_PARAGRAPH">
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
        <template #customEmail>
          <code>{{ customEmail }}</code>
        </template>
      </gl-sprintf>
    </p>
    <p>
      {{ $options.I18N_MODAL_SET_UP_AGAIN_PARAGRAPH }}
    </p>
  </gl-modal>
</template>
