<script>
import RecoveryCode from './recovery_code.vue';
import TotpCode from './totp_code.vue';
import WebauthnAuthentication from './webauthn_authentication.vue';

/**
 * @typedef {'recovery'|'totp'|'webauthn'} Method
 */

export default {
  name: 'TwoFactorAuthentication',
  components: {
    RecoveryCode,
    TotpCode,
    WebauthnAuthentication,
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
    webauthnParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      /** @type {Method} */
      method: this.activeMethod || (this.webauthnEnabled ? 'webauthn' : 'totp'),
    };
  },
  methods: {
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
      this.setMethod(this.totpEnabled ? 'totp' : 'recovery');
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
      @switch-method="setMethod"
      @webauthn-not-supported="onWebauthnNotSupported"
    />
    <totp-code
      v-else-if="isMethod('totp')"
      :path="path"
      :remember-me="rememberMe"
      :remember-me-enabled="rememberMeEnabled"
      :webauthn-enabled="webauthnEnabled"
      @switch-method="setMethod"
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
