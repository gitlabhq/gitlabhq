<script>
import { GlButton, GlForm, GlLink, GlSprintf } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import EmailVerification from '~/sessions/new/components/email_verification.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { supported, convertGetParams, convertGetResponse } from '../util';
import { WEBAUTHN_AUTHENTICATE } from '../constants';
import WebAuthnError from '../error';

export default {
  name: 'WebAuthnAuthenticate',
  components: {
    GlForm,
    GlButton,
    GlLink,
    GlSprintf,
    EmailVerification,
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
      abortController: new AbortController(),
      inProgress: false,
      isAuthenticated: false,
      errorMessage: '',
      errorName: '',
      deviceResponse: '',
      fallbackMode: false,
      showEmailVerification: false,
      isSendingEmailOtp: false,
    };
  },
  computed: {
    showFooter() {
      return this.errorMessage && this.sendEmailOtpPath;
    },
    recoveryCodeLinkPath() {
      return helpPagePath('user/profile/account/two_factor_authentication', {
        anchor: 'recovery-codes',
      });
    },
  },
  mounted() {
    if (this.isWebauthnSupported()) {
      this.authenticate();
    } else {
      this.switchToFallbackUI();
    }
  },
  destroyed() {
    this.abortController.abort();
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
    async sendEmailOtp() {
      this.abortController.abort();

      try {
        this.isSendingEmailOtp = true;
        await axios.post(this.sendEmailOtpPath, {
          user: { login: this.username },
        });
        // Hide the 2FA form
        document.querySelector('.js-2fa-form').classList.add('hidden');
        // Show email verification component
        this.showEmailVerification = true;
        // Hide WebAuthn UI
        this.fallbackMode = true;
      } catch (error) {
        this.errorMessage = __(
          'Failed to send email OTP. Please try again. If the problem persists, please refresh your page or sign in again.',
        );
        this.errorName = error.message;
      } finally {
        this.isSendingEmailOtp = false;
      }
    },
    async authenticate() {
      this.inProgress = true;
      try {
        const response = await navigator.credentials.get({
          publicKey: convertGetParams(this.webauthnParams),
          signal: this.abortController.signal,
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
  <div>
    <div v-if="!fallbackMode && !showEmailVerification" class="gl-text-center">
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
          <input
            v-if="renderRememberMe"
            type="hidden"
            name="user[remember_me]"
            :value="rememberMe"
          />
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

      <div v-if="showFooter" class="gl-mt-4 gl-text-subtle">
        <gl-sprintf
          :message="
            __(
              'Having trouble signing in? %{recoveryCodeLinkStart}Enter recovery code%{recoveryCodeLinkEnd} or %{sendCodeLinkStart}send code to email address%{sendCodeLinkEnd}.',
            )
          "
        >
          <template #recoveryCodeLink>
            <gl-link :href="recoveryCodeLinkPath" target="_blank">
              {{ __('Enter recovery code') }}
            </gl-link>
          </template>
          <template #sendCodeLink="{ content }">
            <gl-button
              variant="link"
              :loading="isSendingEmailOtp"
              :disabled="isSendingEmailOtp"
              category="tertiary"
              data-testid="send-email-otp-link"
              @click="sendEmailOtp"
            >
              {{ content }}
            </gl-button>
          </template>
        </gl-sprintf>
      </div>
    </div>

    <email-verification
      v-if="showEmailVerification && emailVerificationData"
      v-bind="emailVerificationData"
    />
  </div>
</template>
