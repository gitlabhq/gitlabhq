<script>
import { GlAlert, GlButton, GlForm, GlFormInput, GlFormGroup, GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import PasswordInput from '~/authentication/password/components/password_input.vue';
import csrf from '~/lib/utils/csrf';
import { s__ } from '~/locale';
import { WEBAUTHN_REGISTER } from '../constants';
import WebAuthnError from '../error';
import { convertCreateParams, convertCreateResponse, isHTTPS, supported } from '../util';

export default {
  name: 'PasskeyRegistration',
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormInput,
    GlFormGroup,
    GlLoadingIcon,
    PasswordInput,
  },
  inject: ['initialError', 'passwordRequired', 'path', 'twoFactorAuthPath'],
  data() {
    return {
      alert: null,
      /** @type {'pending'|'success'|'error'} */
      state: 'error',
      credentials: null,
    };
  },
  created() {
    if (this.initialError) {
      this.setDangerAlert(this.initialError);
    } else if (supported()) {
      this.onRegister();
    } else {
      const message = isHTTPS()
        ? s__("Add passkey|Your browser doesn't support passkeys.")
        : s__(
            'Add passkey|Passkeys only works with HTTPS-enabled websites. Contact your administrator for more details.',
          );
      this.setDangerAlert(message);
    }
  },
  methods: {
    isState(state) {
      return this.state === state;
    },
    async onRegister() {
      this.alert?.dismiss();
      this.state = 'pending';

      try {
        const credentials = await navigator.credentials.create({
          publicKey: convertCreateParams(gon.webauthn.options),
        });

        this.credentials = JSON.stringify(convertCreateResponse(credentials));
        this.state = 'success';
      } catch (error) {
        const message = new WebAuthnError(error, WEBAUTHN_REGISTER).message();
        this.setDangerAlert(message);
      }
    },
    setDangerAlert(message) {
      this.alert?.dismiss();
      this.alert = createAlert({ message, variant: 'danger' });
      this.state = 'error';
    },
  },
  csrfToken: csrf.token,
};
</script>

<template>
  <div>
    <gl-alert
      v-if="isState('pending')"
      :dismissible="false"
      data-testid="passkey-registration-pending"
    >
      {{
        __(
          'Trying to communicate with your device. Plug it in (if needed) and press the button on the device now.',
        )
      }}
      <gl-loading-icon size="md" class="gl-mt-5" />
    </gl-alert>

    <div v-else-if="isState('success')" class="row" data-testid="passkey-registration-success">
      <gl-form method="post" :action="path" class="gl-col-5">
        <gl-form-group
          v-if="passwordRequired"
          :description="s__('Add passkey|Verify your password to add the passkey')"
          :label="__('Current password')"
          label-for="passkey-registration-current-password"
        >
          <password-input
            id="passkey-registration-current-password"
            name="current_password"
            data-testid="current-password-input"
          />
        </gl-form-group>

        <gl-form-group
          :description="s__('Add passkey|Add a name to help you identify the passkey later')"
          :label="s__('Add passkey|Passkey name')"
          label-for="device-name"
        >
          <gl-form-input
            id="device-name"
            name="device_registration[name]"
            :placeholder="__('Macbook Touch ID on Edge')"
            data-testid="device-name-input"
          />
        </gl-form-group>

        <input type="hidden" name="device_registration[device_response]" :value="credentials" />
        <input type="hidden" name="authenticity_token" :value="$options.csrfToken" />

        <div class="gl-flex gl-gap-3">
          <gl-button type="submit" variant="confirm">{{
            s__('Add passkey|Add passkey')
          }}</gl-button>
          <gl-button data-testid="cancel-btn" :href="twoFactorAuthPath">{{
            __('Cancel')
          }}</gl-button>
        </div>
      </gl-form>
    </div>

    <div v-if="!isState('success')" class="gl-mt-5 gl-flex gl-gap-3">
      <gl-button variant="confirm" @click="onRegister">{{ __('Try again') }}</gl-button>
      <gl-button data-testid="cancel-btn" :href="twoFactorAuthPath">{{ __('Cancel') }}</gl-button>
    </div>
  </div>
</template>
