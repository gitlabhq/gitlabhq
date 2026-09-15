<script>
import { GlButton, GlForm, GlLink, GlSprintf } from '@gitlab/ui';
import illustration from '@gitlab/svgs/dist/illustrations/empty-state/empty-key-md.svg?url';
import { createAlert } from '~/alert';
import { helpPagePath } from '~/helpers/help_page_helper';
import csrf from '~/lib/utils/csrf';
import { newUserSessionPath } from '~/lib/utils/path_helpers/routes';
import { s__ } from '~/locale';
import {
  supported,
  convertGetParams,
  convertGetResponse,
  isSecureContext,
} from '~/authentication/webauthn/util';
import { WEBAUTHN_AUTHENTICATE } from '~/authentication/webauthn/constants';
import WebAuthnError from '~/authentication/webauthn/error';
import { applyDeepLinkFragment } from '~/authentication/sessions/post_signin_fragment';
import VerificationLayout from './verification_layout.vue';

export default {
  name: 'PasskeyAuthentication',
  components: {
    GlButton,
    GlForm,
    GlLink,
    GlSprintf,
    VerificationLayout,
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
    webauthnParams: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      alert: null,
      deviceResponse: '',
      /** @type {null|'pending'|'success'} */
      state: null,
    };
  },
  computed: {
    // Stays true through 'success' too: submit() only starts the navigation, so the page is
    // still here and a second credentials.get() would raise a fresh prompt mid-request.
    isBusy() {
      return this.state !== null;
    },
    actionPath() {
      return applyDeepLinkFragment(this.path);
    },
  },
  mounted() {
    if (supported()) {
      this.authenticate();
    } else {
      const message = isSecureContext()
        ? s__("PasskeyAuthentication|Your browser doesn't support passkeys.")
        : s__(
            'PasskeyAuthentication|Passkeys only works with HTTPS-enabled websites. Contact your administrator for more details.',
          );
      this.setDangerAlert(message);
    }
  },
  methods: {
    newUserSessionPath,
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
        this.state = null;
        this.setDangerAlert(new WebAuthnError(err, WEBAUTHN_AUTHENTICATE).message());
      }
    },
    isState(state) {
      return this.state === state;
    },
    setDangerAlert(message) {
      this.alert = createAlert({ message, variant: 'danger' });
    },
  },
  csrf,
  illustration,
  troubleshootingHelpPath: helpPagePath('auth/passkeys', { anchor: 'troubleshooting' }),
};
</script>

<template>
  <verification-layout
    :svg-path="$options.illustration"
    :title="s__('PasskeyAuthentication|Sign in with passkey')"
  >
    <template #description>
      {{
        s__(
          'PasskeyAuthentication|Follow the instructions on your browser or password manager to continue. Insert your physical key, if you have any.',
        )
      }}
    </template>

    <p aria-live="polite" class="gl-text-subtle" data-testid="passkey-authentication-status">
      <template v-if="isState('pending')">
        {{
          __(
            "Trying to communicate with your device. Plug it in (if you haven't already) and press the button on the device now.",
          )
        }}
      </template>
      <template v-else-if="isState('success')">
        {{ s__('PasskeyAuthentication|We heard back from your device. Authenticating...') }}
      </template>
    </p>

    <gl-form ref="form" :action="actionPath" method="post" class="gl-hidden">
      <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
      <input type="hidden" name="device_response" :value="deviceResponse" />
      <input type="hidden" name="remember_me" :value="rememberMe" />
    </gl-form>

    <div class="gl-flex gl-flex-col gl-gap-3">
      <gl-button
        accessible-disabled
        block
        data-testid="passkey-authentication-try-again"
        :disabled="isBusy"
        variant="confirm"
        @click="authenticate"
        >{{ __('Try again') }}</gl-button
      >

      <gl-button block data-testid="passkey-authentication-back" :href="newUserSessionPath()">{{
        s__('PasskeyAuthentication|Back to sign-in')
      }}</gl-button>
    </div>

    <p class="gl-mt-5 gl-text-subtle">
      <gl-sprintf
        :message="
          s__(
            'PasskeyAuthentication|Having trouble signing in? %{linkStart}Troubleshoot passkey%{linkEnd}',
          )
        "
      >
        <template #link="{ content }">
          <gl-link
            data-testid="passkey-authentication-troubleshoot"
            :href="$options.troubleshootingHelpPath"
            >{{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
    </p>
  </verification-layout>
</template>
