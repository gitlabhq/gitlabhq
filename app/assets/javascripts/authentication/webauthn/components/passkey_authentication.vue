<script>
import { GlButton, GlForm, GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import csrf from '~/lib/utils/csrf';
import { s__ } from '~/locale';
import { supported, convertGetParams, convertGetResponse, isHTTPS } from '../util';
import { WEBAUTHN_AUTHENTICATE } from '../constants';
import WebAuthnError from '../error';

export default {
  name: 'PasskeyAuthentication',
  components: {
    GlButton,
    GlForm,
    GlLoadingIcon,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
    rememberMe: {
      type: String,
      required: true,
    },
    signInPath: {
      type: String,
      required: true,
    },
    webauthnParams: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      alert: null,
      deviceResponse: '',
      /** @type {null|'pending'|'success'|'error'} */
      state: null,
    };
  },
  mounted() {
    if (supported()) {
      this.authenticate();
    } else {
      const message = isHTTPS()
        ? s__("PasskeyAuthentication|Your browser doesn't support passkeys.")
        : s__(
            'PasskeyAuthentication|Passkeys only works with HTTPS-enabled websites. Contact your administrator for more details.',
          );
      this.setDangerAlert(message);
    }
  },
  methods: {
    async authenticate() {
      this.alert?.dismiss();
      this.state = 'pending';
      try {
        const response = await navigator.credentials.get({
          publicKey: convertGetParams(this.webauthnParams),
        });
        const convertedResponse = convertGetResponse(response);
        this.deviceResponse = JSON.stringify(convertedResponse);
        this.state = 'success';
        await this.$nextTick();
        this.$refs.form.$el.submit();
      } catch (err) {
        const message = new WebAuthnError(err, WEBAUTHN_AUTHENTICATE).message();
        this.setDangerAlert(message);
      }
    },
    isState(state) {
      return this.state === state;
    },
    setDangerAlert(message) {
      this.alert = createAlert({ message, variant: 'danger' });
      this.state = 'error';
    },
  },
  csrf,
};
</script>

<template>
  <div class="gl-text-center">
    <div v-if="isState('pending')" data-testid="passkey-authentication-pending">
      <p>
        {{
          __(
            "Trying to communicate with your device. Plug it in (if you haven't already) and press the button on the device now.",
          )
        }}
      </p>
      <gl-loading-icon size="md" class="gl-my-5" />
    </div>

    <div v-else-if="isState('success')" data-testid="passkey-authentication-success">
      <p>
        {{ s__('PasskeyAuthentication|We heard back from your device. Authenticating...') }}
      </p>
      <gl-loading-icon size="md" class="gl-my-5" />

      <gl-form ref="form" :action="path" method="post">
        <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
        <input type="hidden" name="device_response" :value="deviceResponse" />
        <input type="hidden" name="remember_me" :value="rememberMe" />
      </gl-form>
    </div>

    <div v-else-if="isState('error')" class="gl-mb-3">
      <gl-button data-testid="passkey-authentication-try-again" :block="true" @click="authenticate">
        {{ __('Try again') }}
      </gl-button>
    </div>

    <gl-button
      data-testid="passkey-authentication-back"
      :block="true"
      :href="signInPath"
      variant="confirm"
    >
      {{ s__('PasskeyAuthentication|Back to sign-in') }}
    </gl-button>
  </div>
</template>
