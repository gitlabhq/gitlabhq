<script>
import { GlAlert, GlModal, GlFormGroup, GlFormInput, GlSprintf } from '@gitlab/ui';
import {
  CONFIRM_DANGER_MODAL_BUTTON,
  CONFIRM_DANGER_MODAL_TITLE,
  CONFIRM_DANGER_PHRASE_TEXT,
  CONFIRM_DANGER_WARNING,
  CONFIRM_DANGER_MODAL_ERROR,
} from './constants';

export default {
  name: 'ConfirmDangerModal',
  components: {
    GlAlert,
    GlModal,
    GlFormGroup,
    GlFormInput,
    GlSprintf,
  },
  inject: {
    confirmDangerMessage: {
      default: '',
    },
    confirmButtonText: {
      default: CONFIRM_DANGER_MODAL_BUTTON,
    },
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    phrase: {
      type: String,
      required: true,
    },
  },
  data() {
    return { confirmationPhrase: '' };
  },
  computed: {
    isValid() {
      return Boolean(
        this.confirmationPhrase.length && this.equalString(this.confirmationPhrase, this.phrase),
      );
    },
    actionPrimary() {
      return {
        text: this.confirmButtonText,
        attributes: [{ variant: 'danger', disabled: !this.isValid }],
      };
    },
  },
  methods: {
    equalString(a, b) {
      return a.trim().toLowerCase() === b.trim().toLowerCase();
    },
  },
  i18n: {
    CONFIRM_DANGER_MODAL_BUTTON,
    CONFIRM_DANGER_MODAL_TITLE,
    CONFIRM_DANGER_WARNING,
    CONFIRM_DANGER_PHRASE_TEXT,
    CONFIRM_DANGER_MODAL_ERROR,
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    :data-testid="modalId"
    :title="$options.i18n.CONFIRM_DANGER_MODAL_TITLE"
    :action-primary="actionPrimary"
    @primary="$emit('confirm')"
  >
    <gl-alert
      v-if="confirmDangerMessage"
      variant="danger"
      data-testid="confirm-danger-message"
      :dismissible="false"
      class="gl-mb-4"
    >
      {{ confirmDangerMessage }}
    </gl-alert>
    <p data-testid="confirm-danger-warning">{{ $options.i18n.CONFIRM_DANGER_WARNING }}</p>
    <p data-testid="confirm-danger-phrase">
      <gl-sprintf :message="$options.i18n.CONFIRM_DANGER_PHRASE_TEXT">
        <template #phrase_code>
          <code>{{ phrase }}</code>
        </template>
      </gl-sprintf>
    </p>
    <gl-form-group :state="isValid" :invalid-feedback="$options.i18n.CONFIRM_DANGER_MODAL_ERROR">
      <gl-form-input
        id="confirm_name_input"
        v-model="confirmationPhrase"
        class="form-control"
        data-testid="confirm-danger-input"
        type="text"
      />
    </gl-form-group>
  </gl-modal>
</template>
