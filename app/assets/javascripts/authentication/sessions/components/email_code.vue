<script>
import { GlForm, GlFormFields, GlButton, GlSprintf } from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/src/utils';
import illustration from '@gitlab/svgs/dist/illustrations/email-verification-md.svg?url';
import { s__ } from '~/locale';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import axios from '~/lib/utils/axios_utils';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';
import {
  I18N_INPUT_LABEL,
  I18N_EMAIL_EMPTY_CODE,
  I18N_EMAIL_INVALID_CODE,
  I18N_SUBMIT_BUTTON,
  I18N_DIDNT_GET_CODE_RESEND_LINK,
  I18N_RESEND_CODE,
  I18N_RESEND_CODE_IN,
  I18N_EMAIL_RESEND_SUCCESS,
  I18N_GENERIC_ERROR,
  I18N_SEND_TO_SECONDARY_EMAIL_GUIDE,
  VERIFICATION_CODE_REGEX,
  SUCCESS_RESPONSE,
} from '~/sessions/new/constants';
import EmailForm from '~/sessions/new/components/email_form.vue';
import { newUserSessionPath } from '~/lib/utils/path_helpers/routes';
import VerificationLayout from './verification_layout.vue';

const VERIFY_CODE_FORM = 'VERIFY_CODE_FORM';
const ANOTHER_EMAIL_FORM = 'ANOTHER_EMAIL_FORM';
const FIELD_KEY = 'verificationCode';

export default {
  name: 'EmailCode',
  components: {
    GlForm,
    GlFormFields,
    GlButton,
    GlSprintf,
    GlCountdown,
    EmailForm,
    VerificationLayout,
  },
  props: {
    sendEmailOtpPath: {
      type: String,
      required: true,
    },
    emailVerificationData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      email: this.emailVerificationData.obfuscatedEmail,
      values: { [FIELD_KEY]: '' },
      verifyError: '',
      activeForm: VERIFY_CODE_FORM,
      isSending: false,
      showResendAfter: 0,
    };
  },
  computed: {
    serverValidations() {
      return { [FIELD_KEY]: this.verifyError };
    },
    showResend() {
      return new Date(this.showResendAfter) <= new Date();
    },
    resendAfterDateString() {
      return new Date(this.showResendAfter).toString();
    },
  },
  watch: {
    // Clear a stale server error as soon as the user edits the code.
    'values.verificationCode': function clearVerifyError() {
      this.verifyError = '';
    },
  },
  mounted() {
    this.sendCode();
  },
  methods: {
    newUserSessionPath,
    async sendCode() {
      this.isSending = true;
      try {
        const { data } = await axios.post(this.sendEmailOtpPath, {
          user: { login: this.emailVerificationData.username },
        });
        this.showResendAfter = data.show_resend_after ?? 0;
      } catch (error) {
        const message = error?.response?.data?.message;
        if (message) {
          createAlert({ message });
        } else {
          this.handleError(error);
        }
      } finally {
        this.isSending = false;
      }
    },
    async verify() {
      try {
        const { data } = await axios.post(this.emailVerificationData.verifyPath, {
          user: { verification_token: this.values[FIELD_KEY] },
        });
        if (data.status === SUCCESS_RESPONSE) {
          visitUrl(data.redirect_path);
        } else {
          this.handleError();
        }
      } catch (error) {
        const message = error?.response?.data?.message;
        if (message) {
          this.verifyError = message;
        } else {
          this.handleError(error);
        }
      }
    },
    async resend(email = '') {
      this.isSending = true;
      try {
        const { data } = await axios.post(this.emailVerificationData.resendPath, {
          user: { email },
        });
        if (data.status === SUCCESS_RESPONSE) {
          this.showResendAfter = data.show_resend_after ?? 0;
          createAlert({
            message: I18N_EMAIL_RESEND_SUCCESS,
            variant: VARIANT_SUCCESS,
          });
        } else {
          this.handleError();
        }
      } catch (error) {
        const message = error?.response?.data?.message;
        if (message) {
          createAlert({ message });
        } else {
          this.handleError(error);
        }
      } finally {
        this.isSending = false;
        this.resetForm();
      }
    },
    sendToAnotherEmail(email) {
      this.showVerifyCodeForm(email);
      this.resend(email);
    },
    onResendTimerExpired() {
      this.showResendAfter = 0;
    },
    handleError(error) {
      createAlert({
        message: I18N_GENERIC_ERROR,
        captureError: true,
        error,
      });
    },
    resetForm() {
      this.values = { [FIELD_KEY]: '' };
      this.verifyError = '';
      this.$nextTick(() => {
        document.getElementById('email-code')?.focus();
      });
    },
    showVerifyCodeForm(email = '') {
      this.activeForm = this.$options.forms.verifyCodeForm;
      if (email.length) this.email = email;
      this.resetForm();
    },
    showAnotherEmailForm() {
      this.activeForm = this.$options.forms.anotherEmailForm;
    },
  },
  illustration,
  fields: {
    [FIELD_KEY]: {
      id: 'email-code',
      label: I18N_INPUT_LABEL,
      validators: [
        formValidators.required(I18N_EMAIL_EMPTY_CODE),
        (value) => (!value || VERIFICATION_CODE_REGEX.test(value) ? '' : I18N_EMAIL_INVALID_CODE),
      ],
      inputAttrs: {
        autocomplete: 'one-time-code',
        autofocus: true,
        'data-testid': 'email-code-field',
        inputmode: 'numeric',
        maxlength: '6',
        placeholder: s__('TwoFactorAuth|Enter 6 digit code'),
      },
    },
  },
  i18n: {
    title: s__('TwoFactorAuth|Authenticate with your email'),
    description: s__(
      'TwoFactorAuth|We sent a code to %{email} to verify your identity. Keep this window open while checking your code.',
    ),
    submitButton: I18N_SUBMIT_BUTTON,
    useAnotherEmailButton: s__('TwoFactorAuth|Use another email'),
    didntGetCodeResendLink: I18N_DIDNT_GET_CODE_RESEND_LINK,
    resendCodeIn: I18N_RESEND_CODE_IN,
    resendCode: I18N_RESEND_CODE,
    anotherEmailGuide: I18N_SEND_TO_SECONDARY_EMAIL_GUIDE,
  },
  forms: {
    verifyCodeForm: VERIFY_CODE_FORM,
    anotherEmailForm: ANOTHER_EMAIL_FORM,
  },
};
</script>

<template>
  <verification-layout :svg-path="$options.illustration" :title="$options.i18n.title">
    <email-form
      v-if="activeForm === $options.forms.anotherEmailForm"
      :form-info="$options.i18n.anotherEmailGuide"
      :submit-text="$options.i18n.resendCode"
      data-testid="another-email-form"
      @submit-email="sendToAnotherEmail"
      @cancel="showVerifyCodeForm"
    />
    <gl-form v-else id="email-otp-form" data-testid="verify-code-form">
      <section class="gl-mb-5 gl-text-subtle">
        <gl-sprintf :message="$options.i18n.description">
          <template #email>
            <strong>{{ email }}</strong>
          </template>
        </gl-sprintf>
      </section>

      <gl-form-fields
        v-model="values"
        form-id="email-otp-form"
        :fields="$options.fields"
        :server-validations="serverValidations"
        :validate-on-blur="false"
        @submit="verify"
      >
        <template #group(verificationCode)-description>
          <gl-sprintf
            v-if="showResend || isSending"
            :message="$options.i18n.didntGetCodeResendLink"
          >
            <template #button="{ content }">
              <gl-button
                class="gl-align-baseline"
                variant="link"
                category="tertiary"
                data-testid="resend-button"
                :loading="isSending"
                :disabled="isSending"
                @click="() => resend()"
              >
                {{ content }}
              </gl-button>
            </template>
          </gl-sprintf>
          <gl-sprintf v-else :message="$options.i18n.resendCodeIn">
            <template #timer>
              <gl-countdown
                class="gl-inline-block"
                :end-date-string="resendAfterDateString"
                @timer-expired="onResendTimerExpired"
              />
            </template>
          </gl-sprintf>
        </template>
      </gl-form-fields>

      <section class="gl-mt-5 gl-flex gl-flex-col gl-gap-3">
        <gl-button
          block
          class="js-no-auto-disable"
          variant="confirm"
          type="submit"
          data-testid="verify-code-button"
          >{{ $options.i18n.submitButton }}</gl-button
        >
        <gl-button block data-testid="use-another-email-button" @click="showAnotherEmailForm">{{
          $options.i18n.useAnotherEmailButton
        }}</gl-button>
        <gl-button block :href="newUserSessionPath()" data-testid="back-to-sign-in-button">{{
          s__('TwoFactorAuth|Back to sign-in')
        }}</gl-button>
      </section>
    </gl-form>
  </verification-layout>
</template>
