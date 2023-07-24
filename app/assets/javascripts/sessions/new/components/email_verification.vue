<script>
import { GlSprintf, GlForm, GlFormGroup, GlFormInput, GlButton } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import {
  I18N_EXPLANATION,
  I18N_INPUT_LABEL,
  I18N_EMAIL_EMPTY_CODE,
  I18N_EMAIL_INVALID_CODE,
  I18N_SUBMIT_BUTTON,
  I18N_RESEND_LINK,
  I18N_EMAIL_RESEND_SUCCESS,
  I18N_GENERIC_ERROR,
  VERIFICATION_CODE_REGEX,
  SUCCESS_RESPONSE,
  FAILURE_RESPONSE,
} from '../constants';

export default {
  name: 'EmailVerification',
  components: {
    GlSprintf,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlButton,
  },
  props: {
    obfuscatedEmail: {
      type: String,
      required: true,
    },
    verifyPath: {
      type: String,
      required: true,
    },
    resendPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      verificationCode: '',
      submitted: false,
      verifyError: '',
    };
  },
  computed: {
    inputValidation() {
      return {
        state: !(this.submitted && this.invalidFeedback),
        message: this.invalidFeedback,
      };
    },
    invalidFeedback() {
      if (!this.submitted) {
        return '';
      }

      if (!this.verificationCode) {
        return I18N_EMAIL_EMPTY_CODE;
      }

      if (!VERIFICATION_CODE_REGEX.test(this.verificationCode)) {
        return I18N_EMAIL_INVALID_CODE;
      }

      return this.verifyError;
    },
  },
  watch: {
    verificationCode() {
      this.verifyError = '';
    },
  },
  methods: {
    verify() {
      this.submitted = true;

      if (!this.inputValidation.state) return;

      axios
        .post(this.verifyPath, { user: { verification_token: this.verificationCode } })
        .then(this.handleVerificationResponse)
        .catch(this.handleError);
    },
    handleVerificationResponse(response) {
      if (response.data.status === undefined) {
        this.handleError();
      } else if (response.data.status === SUCCESS_RESPONSE) {
        visitUrl(response.data.redirect_path);
      } else if (response.data.status === FAILURE_RESPONSE) {
        this.verifyError = response.data.message;
      }
    },
    resend() {
      axios
        .post(this.resendPath)
        .then(this.handleResendResponse)
        .catch(this.handleError)
        .finally(this.resetForm);
    },
    handleResendResponse(response) {
      if (response.data.status === undefined) {
        this.handleError();
      } else if (response.data.status === SUCCESS_RESPONSE) {
        createAlert({
          message: I18N_EMAIL_RESEND_SUCCESS,
          variant: VARIANT_SUCCESS,
        });
      } else if (response.data.status === FAILURE_RESPONSE) {
        createAlert({ message: response.data.message });
      }
    },
    handleError(error) {
      createAlert({
        message: I18N_GENERIC_ERROR,
        captureError: true,
        error,
      });
    },
    resetForm() {
      this.verificationCode = '';
      this.submitted = false;
      this.$refs.input.$el.focus();
    },
  },
  i18n: {
    explanation: I18N_EXPLANATION,
    inputLabel: I18N_INPUT_LABEL,
    submitButton: I18N_SUBMIT_BUTTON,
    resendLink: I18N_RESEND_LINK,
  },
};
</script>

<template>
  <gl-form @submit.prevent="verify">
    <section class="gl-mb-5">
      <gl-sprintf :message="$options.i18n.explanation">
        <template #email>
          <strong>{{ obfuscatedEmail }}</strong>
        </template>
      </gl-sprintf>
    </section>
    <gl-form-group
      :label="$options.i18n.inputLabel"
      label-for="verification-code"
      :state="inputValidation.state"
      :invalid-feedback="inputValidation.message"
    >
      <gl-form-input
        id="verification-code"
        ref="input"
        v-model="verificationCode"
        autofocus
        autocomplete="one-time-code"
        inputmode="numeric"
        maxlength="6"
        :state="inputValidation.state"
      />
    </gl-form-group>
    <section class="gl-mt-5">
      <gl-button block variant="confirm" type="submit" :disabled="!inputValidation.state">{{
        $options.i18n.submitButton
      }}</gl-button>
      <gl-button block variant="link" class="gl-mt-3 gl-h-7" @click="resend">{{
        $options.i18n.resendLink
      }}</gl-button>
    </section>
  </gl-form>
</template>
