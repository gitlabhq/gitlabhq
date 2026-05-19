<script>
import EmailVerification from '~/sessions/new/components/email_verification.vue';
import EmailOtpFallbackFooter from '~/sessions/new/components/email_otp_fallback_footer.vue';
import { createAlert } from '~/alert';

export default {
  name: 'TwoFactorEmailFallback',
  components: {
    EmailVerification,
    EmailOtpFallbackFooter,
  },
  props: {
    sendEmailOtpPath: {
      type: String,
      required: false,
      default: '',
    },
    username: {
      type: String,
      required: false,
      default: '',
    },
    emailVerificationData: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      alert: null,
      showEmailVerification: false,
      initialShowResendAfter: null,
    };
  },
  methods: {
    sendEmailOTPError({ message }) {
      createAlert({ message, variant: 'danger' });
    },
    sendEmailOTPSuccess(showResendAfter) {
      this.alert?.dismiss();
      this.showEmailVerification = true;
      this.initialShowResendAfter = showResendAfter;
    },
  },
};
</script>

<template>
  <div v-if="emailVerificationData">
    <email-otp-fallback-footer
      v-if="!showEmailVerification"
      :send-email-otp-path="sendEmailOtpPath"
      :username="username"
      @success="sendEmailOTPSuccess"
      @error="sendEmailOTPError"
    />

    <email-verification
      v-if="showEmailVerification"
      v-bind="emailVerificationData"
      :initial-show-resend-after="initialShowResendAfter"
    />
  </div>
</template>
