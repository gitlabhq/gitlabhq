<script>
import { GlButton, GlForm } from '@gitlab/ui';
import illustration from '@gitlab/svgs/dist/illustrations/empty-state/empty-key-md.svg?url';
import csrf from '~/lib/utils/csrf';
import { createAlert } from '~/alert';
import { supported, convertGetParams, convertGetResponse } from '~/authentication/webauthn/util';
import { WEBAUTHN_AUTHENTICATE } from '~/authentication/webauthn/constants';
import WebAuthnError from '~/authentication/webauthn/error';
import VerificationLayout from './verification_layout.vue';
import VerificationDivider from './verification_divider.vue';
import VerificationRecoverAccount from './verification_recover_account.vue';

export default {
  name: 'WebAuthnAuthentication',
  components: {
    GlButton,
    GlForm,
    VerificationLayout,
    VerificationDivider,
    VerificationRecoverAccount,
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
    rememberMeEnabled: {
      type: Boolean,
      required: true,
    },
    webauthnParams: {
      type: Object,
      required: true,
    },
    totpEnabled: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['switch-method', 'webauthn-not-supported'],
  data() {
    return {
      // Lets us cancel an in-flight credentials.get() on unmount.
      abortController: new AbortController(),
      inProgress: false,
      deviceResponse: '',
    };
  },
  mounted() {
    if (supported()) {
      this.authenticate();
    } else {
      this.$emit('webauthn-not-supported');
    }
  },
  destroyed() {
    this.abortController.abort();
    this.alert?.dismiss();
  },
  methods: {
    tryAgain() {
      this.authenticate();
    },
    async authenticate() {
      // Dismiss the previous error before a new attempt so alerts don't stack.
      this.alert?.dismiss();
      this.inProgress = true;
      try {
        const opts = {
          publicKey: convertGetParams(this.webauthnParams),
          signal: this.abortController.signal,
        };
        const response = await navigator.credentials.get(opts);
        this.deviceResponse = JSON.stringify(convertGetResponse(response));
        // Let Vue write deviceResponse into the hidden input before the native submit reads it.
        await this.$nextTick();
        this.$refs.form.$el.submit();
      } catch (err) {
        // A get() we aborted ourselves (unmount / method switch) is intentional; surfacing
        // it would leave a stray "(AbortError)" alert behind from the destroyed instance.
        if (this.abortController.signal.aborted) return;

        const webAuthnError = new WebAuthnError(err, WEBAUTHN_AUTHENTICATE);
        // preservePrevious so a client-side device error doesn't wipe a server-rendered
        // flash (e.g. "Authentication via WebAuthn device failed") in the same container.
        this.alert = createAlert({
          message: `${webAuthnError.message()} (${webAuthnError.errorName})`,
          preservePrevious: true,
        });
      } finally {
        this.inProgress = false;
      }
    },
  },
  csrf,
  illustration,
};
</script>

<template>
  <verification-layout
    :svg-path="$options.illustration"
    :title="s__('TwoFactorAuth|Verify with security device')"
  >
    <template #description>
      {{
        s__(
          'TwoFactorAuth|Follow the instructions in your browser or password manager to authenticate with a passkey, laptop, phone, or authenticator like a YubiKey. Insert a physical key, if you have any.',
        )
      }}
    </template>

    <p v-if="inProgress" data-testid="webauthn-in-progress" class="gl-text-subtle">
      {{
        s__(
          "TwoFactorAuth|Trying to communicate with your device. Plug it in (if you haven't already) and follow the instructions.",
        )
      }}
    </p>

    <gl-form ref="form" :action="path" method="post" class="gl-hidden">
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
      <input type="hidden" name="two_factor_method" value="webauthn" />
      <input type="hidden" name="user[device_response]" :value="deviceResponse" />
      <input v-if="rememberMeEnabled" type="hidden" name="user[remember_me]" :value="rememberMe" />
    </gl-form>

    <gl-button
      block
      class="js-no-auto-disable"
      data-testid="try-again-button"
      variant="confirm"
      :disabled="inProgress"
      @click="tryAgain"
      >{{ __('Try again') }}</gl-button
    >

    <template v-if="totpEnabled">
      <verification-divider />
      <gl-button
        block
        data-testid="authenticator-app-button"
        @click="$emit('switch-method', 'totp')"
        >{{ s__('TwoFactorAuth|Authenticator app') }}</gl-button
      >
    </template>

    <verification-recover-account @recover="$emit('switch-method', 'recovery')" />
  </verification-layout>
</template>
