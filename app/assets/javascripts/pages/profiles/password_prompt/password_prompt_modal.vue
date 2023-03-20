<script>
import { GlModal, GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import {
  I18N_PASSWORD_PROMPT_TITLE,
  I18N_PASSWORD_PROMPT_FORM_LABEL,
  I18N_PASSWORD_PROMPT_ERROR_MESSAGE,
  I18N_PASSWORD_PROMPT_CANCEL_BUTTON,
  I18N_PASSWORD_PROMPT_CONFIRM_BUTTON,
} from './constants';

export default {
  components: {
    GlModal,
    GlForm,
    GlFormGroup,
    GlFormInput,
  },
  props: {
    handleConfirmPassword: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      passwordCheck: '',
    };
  },
  computed: {
    isValid() {
      return Boolean(this.passwordCheck.length);
    },
    primaryProps() {
      return {
        text: I18N_PASSWORD_PROMPT_CONFIRM_BUTTON,
        attributes: { variant: 'danger', category: 'primary', disabled: !this.isValid },
      };
    },
  },
  methods: {
    onConfirmPassword() {
      this.handleConfirmPassword(this.passwordCheck);
    },
  },
  cancelProps: {
    text: I18N_PASSWORD_PROMPT_CANCEL_BUTTON,
  },
  i18n: {
    title: I18N_PASSWORD_PROMPT_TITLE,
    formLabel: I18N_PASSWORD_PROMPT_FORM_LABEL,
    errorMessage: I18N_PASSWORD_PROMPT_ERROR_MESSAGE,
  },
};
</script>

<template>
  <gl-modal
    data-testid="password-prompt-modal"
    modal-id="password-prompt-modal"
    :title="$options.i18n.title"
    :action-primary="primaryProps"
    :action-cancel="$options.cancelProps"
    @primary="onConfirmPassword"
  >
    <gl-form @submit.prevent="onConfirmPassword">
      <gl-form-group
        :label="$options.i18n.formLabel"
        label-for="password-prompt-confirmation"
        :invalid-feedback="$options.i18n.errorMessage"
        :state="isValid"
      >
        <gl-form-input
          id="password-prompt-confirmation"
          v-model="passwordCheck"
          name="password-confirmation"
          type="password"
          data-testid="password-prompt-field"
        />
      </gl-form-group>
    </gl-form>
  </gl-modal>
</template>
