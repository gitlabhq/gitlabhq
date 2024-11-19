<script>
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormInput,
  GlFormGroup,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
} from '@gitlab/ui';
import {
  I18N_BUTTON_REGISTER,
  I18N_BUTTON_SETUP,
  I18N_BUTTON_TRY_AGAIN,
  I18N_DEVICE_NAME,
  I18N_DEVICE_NAME_DESCRIPTION,
  I18N_DEVICE_NAME_PLACEHOLDER,
  I18N_ERROR_HTTP,
  I18N_ERROR_UNSUPPORTED_BROWSER,
  I18N_NOTICE,
  I18N_PASSWORD,
  I18N_PASSWORD_DESCRIPTION,
  I18N_STATUS_SUCCESS,
  I18N_STATUS_WAITING,
  STATE_ERROR,
  STATE_READY,
  STATE_SUCCESS,
  STATE_UNSUPPORTED,
  STATE_WAITING,
  WEBAUTHN_DOCUMENTATION_PATH,
  WEBAUTHN_REGISTER,
} from '~/authentication/webauthn/constants';
import WebAuthnError from '~/authentication/webauthn/error';
import {
  convertCreateParams,
  convertCreateResponse,
  isHTTPS,
  supported,
} from '~/authentication/webauthn/util';
import csrf from '~/lib/utils/csrf';

export default {
  name: 'WebAuthnRegistration',
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormInput,
    GlFormGroup,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
  },
  I18N_BUTTON_REGISTER,
  I18N_BUTTON_SETUP,
  I18N_BUTTON_TRY_AGAIN,
  I18N_DEVICE_NAME,
  I18N_DEVICE_NAME_DESCRIPTION,
  I18N_DEVICE_NAME_PLACEHOLDER,
  I18N_ERROR_HTTP,
  I18N_ERROR_UNSUPPORTED_BROWSER,
  I18N_NOTICE,
  I18N_PASSWORD,
  I18N_PASSWORD_DESCRIPTION,
  I18N_STATUS_SUCCESS,
  I18N_STATUS_WAITING,
  STATE_ERROR,
  STATE_READY,
  STATE_SUCCESS,
  STATE_UNSUPPORTED,
  STATE_WAITING,
  WEBAUTHN_DOCUMENTATION_PATH,
  inject: ['initialError', 'passwordRequired', 'targetPath'],
  data() {
    return {
      csrfToken: csrf.token,
      form: { deviceName: '', password: '' },
      state: STATE_UNSUPPORTED,
      errorMessage: this.initialError,
      credentials: null,
    };
  },
  computed: {
    disabled() {
      const isEmptyDeviceName = this.form.deviceName.trim() === '';
      const isEmptyPassword = this.form.password.trim() === '';

      if (this.passwordRequired === false) {
        return isEmptyDeviceName;
      }

      return isEmptyDeviceName || isEmptyPassword;
    },
  },
  created() {
    if (this.errorMessage) {
      this.state = STATE_ERROR;
      return;
    }

    if (supported()) {
      this.state = STATE_READY;
      return;
    }

    this.errorMessage = isHTTPS() ? I18N_ERROR_UNSUPPORTED_BROWSER : I18N_ERROR_HTTP;
  },
  methods: {
    isCurrentState(state) {
      return this.state === state;
    },
    async onRegister() {
      this.state = STATE_WAITING;

      try {
        const credentials = await navigator.credentials.create({
          publicKey: convertCreateParams(gon.webauthn.options),
        });

        this.credentials = JSON.stringify(convertCreateResponse(credentials));
        this.state = STATE_SUCCESS;
      } catch (error) {
        this.errorMessage = new WebAuthnError(error, WEBAUTHN_REGISTER).message();
        this.state = STATE_ERROR;
      }
    },
  },
};
</script>

<template>
  <div class="gl-mb-5">
    <template v-if="isCurrentState($options.STATE_UNSUPPORTED)">
      <gl-alert variant="danger" :dismissible="false">{{ errorMessage }}</gl-alert>
    </template>

    <template v-else-if="isCurrentState($options.STATE_READY)">
      <gl-button variant="confirm" @click="onRegister">{{ $options.I18N_BUTTON_SETUP }}</gl-button>
    </template>

    <template v-else-if="isCurrentState($options.STATE_WAITING)">
      <gl-alert :dismissible="false">
        {{ $options.I18N_STATUS_WAITING }}
        <gl-loading-icon />
      </gl-alert>
    </template>

    <template v-else-if="isCurrentState($options.STATE_SUCCESS)">
      <p>{{ $options.I18N_STATUS_SUCCESS }}</p>
      <gl-alert :dismissible="false" class="gl-mb-5">
        <gl-sprintf :message="$options.I18N_NOTICE">
          <template #link="{ content }">
            <gl-link :href="$options.WEBAUTHN_DOCUMENTATION_PATH" target="_blank">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </gl-alert>

      <gl-form method="post" :action="targetPath" data-testid="create-webauthn">
        <gl-form-group
          v-if="passwordRequired"
          :description="$options.I18N_PASSWORD_DESCRIPTION"
          :label="$options.I18N_PASSWORD"
          label-for="webauthn-registration-current-password"
        >
          <gl-form-input
            id="webauthn-registration-current-password"
            v-model="form.password"
            name="current_password"
            type="password"
            autocomplete="current-password"
            data-testid="current-password-input"
          />
        </gl-form-group>

        <gl-form-group
          :description="$options.I18N_DEVICE_NAME_DESCRIPTION"
          :label="$options.I18N_DEVICE_NAME"
          label-for="device-name"
        >
          <gl-form-input
            id="device-name"
            v-model="form.deviceName"
            name="device_registration[name]"
            :placeholder="$options.I18N_DEVICE_NAME_PLACEHOLDER"
            data-testid="device-name-input"
          />
        </gl-form-group>

        <input type="hidden" name="device_registration[device_response]" :value="credentials" />
        <input :value="csrfToken" type="hidden" name="authenticity_token" />

        <gl-button type="submit" :disabled="disabled" variant="confirm">{{
          $options.I18N_BUTTON_REGISTER
        }}</gl-button>
      </gl-form>
    </template>

    <template v-else-if="isCurrentState($options.STATE_ERROR)">
      <gl-alert
        variant="danger"
        :dismissible="false"
        :secondary-button-text="$options.I18N_BUTTON_TRY_AGAIN"
        @secondaryAction="onRegister"
      >
        {{ errorMessage }}
      </gl-alert>
    </template>
  </div>
</template>
