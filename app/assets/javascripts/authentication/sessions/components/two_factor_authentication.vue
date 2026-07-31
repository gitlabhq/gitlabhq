<script>
import RecoveryCode from './recovery_code.vue';
import TotpCode from './totp_code.vue';
import WebauthnAuthentication from './webauthn_authentication.vue';
import EmailCode from './email_code.vue';

/**
 * @typedef {'recovery'|'totp'|'webauthn'|'email'} Method
 */

export default {
  name: 'TwoFactorAuthentication',
  components: {
    RecoveryCode,
    TotpCode,
    WebauthnAuthentication,
    EmailCode,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
    adminMode: {
      type: Boolean,
      required: false,
      default: false,
    },
    activeMethod: {
      type: String,
      required: false,
      default: '',
    },
    rememberMe: {
      type: String,
      required: true,
    },
    rememberMeEnabled: {
      type: Boolean,
      required: true,
    },
    webauthnEnabled: {
      type: Boolean,
      required: true,
    },
    totpEnabled: {
      type: Boolean,
      required: true,
    },
    emailEnabled: {
      type: Boolean,
      required: true,
    },
    webauthnParams: {
      type: Object,
      required: false,
      default: null,
    },
    sendEmailOtpPath: {
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
      /** @type {Method} */
      method: this.activeMethod || this.defaultMethod(),
    };
  },
  methods: {
    /**
     * @returns {Method}
     */
    defaultMethod() {
      if (this.webauthnEnabled) return 'webauthn';
      if (this.totpEnabled) return 'totp';
      return 'email';
    },
    /**
     * @param {Method} method
     */
    isMethod(method) {
      return this.method === method;
    },
    /**
     * @param {Method} method
     */
    setMethod(method) {
      this.method = method;
    },
    onWebauthnNotSupported() {
      if (this.totpEnabled) {
        this.setMethod('totp');
      } else if (this.emailEnabled) {
        this.setMethod('email');
      } else {
        this.setMethod('recovery');
      }
    },
  },
};
</script>

<template>
  <div>
    <webauthn-authentication
      v-if="isMethod('webauthn')"
      :path="path"
      :remember-me="rememberMe"
      :remember-me-enabled="rememberMeEnabled"
      :webauthn-params="webauthnParams"
      :totp-enabled="totpEnabled"
      :email-enabled="emailEnabled"
      @switch-method="setMethod"
      @webauthn-not-supported="onWebauthnNotSupported"
    />
    <totp-code
      v-else-if="isMethod('totp')"
      :path="path"
      :remember-me="rememberMe"
      :remember-me-enabled="rememberMeEnabled"
      :webauthn-enabled="webauthnEnabled"
      :email-enabled="emailEnabled"
      @switch-method="setMethod"
    />
    <email-code
      v-else-if="isMethod('email')"
      :send-email-otp-path="sendEmailOtpPath"
      :email-verification-data="emailVerificationData"
    />
    <recovery-code
      v-else-if="isMethod('recovery')"
      :path="path"
      :admin-mode="adminMode"
      :remember-me="rememberMe"
      :remember-me-enabled="rememberMeEnabled"
    />
  </div>
</template>
