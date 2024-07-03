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
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: null,
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
    modalTitle: {
      type: String,
      required: false,
      default: CONFIRM_DANGER_MODAL_TITLE,
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
          loading: this.confirmLoading,
          'data-testid': 'confirm-danger-modal-button',
        },
      };
    },
    actionCancel() {
      return {
        text: this.cancelButtonText,
      };
    },
  },
  watch: {
    confirmLoading(isLoading, wasLoading) {
      // If the button was loading and now no longer is
      if (!isLoading && wasLoading) {
        // Hide the modal
        this.$emit('change', false);
      }
    },
  },
  methods: {
    equalString(a, b) {
      return a.trim().toLowerCase() === b.trim().toLowerCase();
    },
    focusConfirmInput() {
      this.$refs.confirmInput.$el.focus();
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
    :visible="visible"
    :modal-id="modalId"
    :data-testid="modalId"
    :title="modalTitle"
    :action-primary="actionPrimary"
    :action-cancel="actionCancel"
    size="sm"
    @primary="$emit('confirm', $event)"
    @change="$emit('change', $event)"
    @shown="focusConfirmInput()"
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
    <slot name="modal-body">
      <p data-testid="confirm-danger-warning">
        {{ additionalInformation }}
      </p>
    </slot>
    <div class="gl-flex gl-flex-wrap">
      <label data-testid="confirm-danger-phrase" for="confirm_name_input" class="gl-mb-1 gl-w-full">
        <gl-sprintf :message="$options.i18n.CONFIRM_DANGER_PHRASE_TEXT" />
      </label>
      <code class="gl-max-w-fit">{{ phrase }}</code>
    </div>
    <gl-form-group :state="isValid" class="gl-mb-0">
      <gl-form-input
        id="confirm_name_input"
        ref="confirmInput"
        v-model="confirmationPhrase"
        class="form-control"
        data-testid="confirm-danger-field"
        type="text"
      />
    </gl-form-group>
    <slot name="modal-footer"></slot>
  </gl-modal>
</template>
