<script>
import { GlButton, GlForm } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { supported, convertGetParams, convertGetResponse } from '../util';
import { WEBAUTHN_AUTHENTICATE } from '../constants';
import WebAuthnError from '../error';

export default {
  name: 'WebAuthnAuthenticate',
  components: {
    GlForm,
    GlButton,
  },
  props: {
    webauthnParams: {
      type: Object,
      required: true,
    },
    targetPath: {
      type: String,
      required: true,
    },
    renderRememberMe: {
      type: Boolean,
      required: true,
    },
    rememberMe: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      inProgress: false,
      isAuthenticated: false,
      errorMessage: '',
      errorName: '',
      deviceResponse: '',
      fallbackMode: false,
    };
  },
  mounted() {
    if (this.isWebauthnSupported()) {
      this.authenticate();
    } else {
      this.switchToFallbackUI();
    }
  },
  methods: {
    tryAgain() {
      this.errorMessage = '';
      this.errorName = '';
      this.authenticate();
    },
    switchToFallbackUI() {
      this.fallbackMode = true;
      document.querySelector('.js-2fa-form').classList.remove('hidden');
    },
    isWebauthnSupported() {
      return supported();
    },
    formSubmit() {
      this.$refs.loginToken2faForm.$el.submit();
    },
    async authenticate() {
      this.inProgress = true;
      try {
        const response = await navigator.credentials.get({
          publicKey: convertGetParams(this.webauthnParams),
        });
        const convertedResponse = convertGetResponse(response);
        this.deviceResponse = JSON.stringify(convertedResponse);
        this.isAuthenticated = true;
        await this.$nextTick();
        this.formSubmit();
      } catch (err) {
        const webAuthnError = new WebAuthnError(err, WEBAUTHN_AUTHENTICATE);

        this.errorMessage = webAuthnError.message();
        this.errorName = webAuthnError.errorName;
        this.isAuthenticated = false;
      } finally {
        this.inProgress = false;
      }
    },
  },
  csrf,
};
</script>

<template>
  <div v-if="!fallbackMode" class="gl-text-center">
    <p v-if="inProgress" id="js-authenticate-token-2fa-in-progress">
      {{
        __(
          "Trying to communicate with your device. Plug it in (if you haven't already) and press the button on the device now.",
        )
      }}
    </p>

    <div v-if="isAuthenticated" id="js-authenticate-token-2fa-authenticated">
      <p>
        {{ __('We heard back from your device. You have been authenticated.') }}
      </p>

      <gl-form
        id="js-login-token-2fa-form"
        ref="loginToken2faForm"
        :action="targetPath"
        method="post"
        accept-charset="UTF-8"
      >
        <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
        <input type="hidden" name="user[device_response]" :value="deviceResponse" />
        <input v-if="renderRememberMe" type="hidden" name="user[remember_me]" :value="rememberMe" />
      </gl-form>
    </div>

    <div v-if="errorMessage" id="js-authenticate-token-2fa-error" class="gl-mb-3">
      <p>{{ errorMessage }} ({{ errorName }})</p>

      <gl-button
        id="js-token-2fa-try-again"
        data-testid="confirm-2fa"
        :block="true"
        @click="tryAgain"
      >
        {{ __('Try again?') }}
      </gl-button>
    </div>

    <gl-button
      id="js-login-2fa-device"
      category="primary"
      variant="confirm"
      :block="true"
      @click="switchToFallbackUI"
    >
      {{ __('Sign in via 2FA code') }}
    </gl-button>
  </div>
</template>
