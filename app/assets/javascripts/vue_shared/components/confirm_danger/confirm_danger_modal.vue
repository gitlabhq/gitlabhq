<script>
import { GlAlert, GlModal, GlFormGroup, GlFormInput, GlSprintf } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import {
  CONFIRM_DANGER_MODAL_BUTTON,
  CONFIRM_DANGER_MODAL_TITLE,
  CONFIRM_DANGER_PHRASE_TEXT,
  CONFIRM_DANGER_WARNING,
  CONFIRM_DANGER_MODAL_CANCEL,
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
  directives: {
    SafeHtml,
  },
  inject: {
    htmlConfirmationMessage: {
      default: false,
    },
    confirmDangerMessage: {
      default: '',
    },
    confirmButtonText: {
      default: CONFIRM_DANGER_MODAL_BUTTON,
    },
    additionalInformation: {
      default: CONFIRM_DANGER_WARNING,
    },
    cancelButtonText: {
      default: CONFIRM_DANGER_MODAL_CANCEL,
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
        attributes: {
          variant: 'danger',
          disabled: !this.isValid,
          'data-qa-selector': 'confirm_danger_modal_button',
        },
      };
    },
    actionCancel() {
      return {
        text: this.cancelButtonText,
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
    :action-cancel="actionCancel"
    @primary="$emit('confirm')"
  >
    <gl-alert
      v-if="confirmDangerMessage"
      variant="danger"
      data-testid="confirm-danger-message"
      :dismissible="false"
      class="gl-mb-4"
    >
      <span v-if="htmlConfirmationMessage" v-safe-html="confirmDangerMessage"></span>
      <span v-else>
        {{ confirmDangerMessage }}
      </span>
    </gl-alert>
    <p data-testid="confirm-danger-warning">{{ additionalInformation }}</p>
    <p data-testid="confirm-danger-phrase">
      <gl-sprintf :message="$options.i18n.CONFIRM_DANGER_PHRASE_TEXT">
        <template #phrase_code>
          <code>{{ phrase }}</code>
        </template>
      </gl-sprintf>
    </p>
    <gl-form-group :state="isValid">
      <gl-form-input
        id="confirm_name_input"
        v-model="confirmationPhrase"
        class="form-control"
        data-qa-selector="confirm_danger_field"
        data-testid="confirm-danger-input"
        type="text"
      />
    </gl-form-group>
  </gl-modal>
</template>
