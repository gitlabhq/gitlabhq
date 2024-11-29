<script>
import { GlSprintf, GlForm, GlFormGroup, GlFormInput, GlButton, GlLink } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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
  I18N_UPDATE_EMAIL,
  I18N_HELP_TEXT,
  I18N_SEND_TO_SECONDARY_EMAIL_BUTTON_TEXT,
  I18N_SEND_TO_SECONDARY_EMAIL_GUIDE,
  SUPPORT_URL,
  VERIFICATION_CODE_REGEX,
  SUCCESS_RESPONSE,
  FAILURE_RESPONSE,
} from '../constants';
import EmailForm from './email_form.vue';
import UpdateEmail from './update_email.vue';

const VERIFY_TOKEN_FORM = 'VERIFY_TOKEN_FORM';
const UPDATE_EMAIL_FORM = 'UPDATE_EMAIL_FORM';
const SEND_TO_SECONDARY_EMAIL_FORM = 'SEND_TO_SECONDARY_EMAIL_FORM';

export default {
  name: 'EmailVerification',
  components: {
    GlSprintf,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlButton,
    GlLink,
    EmailForm,
    UpdateEmail,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    username: {
      type: String,
      required: true,
    },
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
    isOfferEmailReset: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      email: this.obfuscatedEmail,
      verificationCode: '',
      submitted: false,
      verifyError: '',
      activeForm: VERIFY_TOKEN_FORM,
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
    resend(email = '') {
      axios
        .post(this.resendPath, { user: { email } })
        .then(this.handleResendResponse)
        .catch(this.handleError)
        .finally(this.resetForm);
    },
    sendToSecondaryEmail(email) {
      this.verifyToken(email);
      this.resend(email);
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
    verifyToken(email = '') {
      this.activeForm = this.$options.forms.verifyTokenForm;
      if (email.length) this.email = email;
      this.$nextTick(this.resetForm);
    },
  },
  i18n: {
    explanation: I18N_EXPLANATION,
    inputLabel: I18N_INPUT_LABEL,
    submitButton: I18N_SUBMIT_BUTTON,
    resendLink: I18N_RESEND_LINK,
    updateEmail: I18N_UPDATE_EMAIL,
    helpText: I18N_HELP_TEXT,
    sendToSecondaryEmailButtonText: I18N_SEND_TO_SECONDARY_EMAIL_BUTTON_TEXT,
    sendToSecondaryEmailGuide: I18N_SEND_TO_SECONDARY_EMAIL_GUIDE,
    supportUrl: SUPPORT_URL,
  },
  forms: {
    verifyTokenForm: VERIFY_TOKEN_FORM,
    updateEmailForm: UPDATE_EMAIL_FORM,
    sendToSecondaryEmailForm: SEND_TO_SECONDARY_EMAIL_FORM,
  },
};
</script>

<template>
  <div>
    <update-email v-if="activeForm === $options.forms.updateEmailForm" @verifyToken="verifyToken" />
    <email-form
      v-else-if="activeForm === $options.forms.sendToSecondaryEmailForm"
      :form-info="$options.i18n.sendToSecondaryEmailGuide"
      :submit-text="$options.i18n.resendLink"
      @submit-email="sendToSecondaryEmail"
      @cancel="verifyToken"
    />
    <gl-form v-else-if="activeForm === $options.forms.verifyTokenForm" @submit.prevent="verify">
      <section class="gl-mb-5">
        <gl-sprintf :message="$options.i18n.explanation">
          <template #username>{{ username }}</template>
          <template #email>
            <strong>{{ email }}</strong>
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
        <gl-button block variant="link" class="gl-mt-3 gl-h-7" @click="() => resend()">{{
          $options.i18n.resendLink
        }}</gl-button>
        <gl-button
          v-if="isOfferEmailReset"
          block
          variant="link"
          class="gl-mt-3 gl-h-7"
          @click="() => (activeForm = $options.forms.updateEmailForm)"
          >{{ $options.i18n.updateEmail }}</gl-button
        >
      </section>
      <p class="gl-mt-3 gl-text-subtle">
        <gl-sprintf :message="$options.i18n.helpText">
          <template #sendToSecondaryEmailButton>
            <gl-button
              class="gl-align-baseline"
              variant="link"
              @click="() => (activeForm = $options.forms.sendToSecondaryEmailForm)"
              >{{ $options.i18n.sendToSecondaryEmailButtonText }}</gl-button
            >
          </template>
          <template #supportLink="{ content }">
            <gl-link :href="$options.i18n.supportUrl" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </gl-form>
  </div>
</template>
