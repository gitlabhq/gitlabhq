<script>
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormFields,
  GlFormPasswordInput,
  GlLoadingIcon,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import csrf from '~/lib/utils/csrf';
import { __, s__ } from '~/locale';
import { WEBAUTHN_REGISTER } from '../constants';
import WebAuthnError from '../error';
import {
  convertCreateParams,
  convertCreateResponse,
  isSecureContext,
  requiredNonBlank,
  supported,
} from '../util';

export default {
  name: 'PasskeyRegistration',
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormFields,
    GlFormPasswordInput,
    GlLoadingIcon,
  },
  formId: 'passkey-registration-form',
  inject: ['initialError', 'passwordRequired', 'path', 'twoFactorAuthPath'],
  data() {
    return {
      alert: null,
      /** @type {'pending'|'success'|'error'} */
      state: 'error',
      credentials: null,
      formFieldsValues: { deviceName: '', password: '' },
    };
  },
  computed: {
    fields() {
      const deviceNameField = {
        deviceName: {
          label: s__('AddPasskey|Passkey name'),
          groupAttrs: {
            description: s__('AddPasskey|Add a name to help you identify the passkey later'),
          },
          validators: [requiredNonBlank(s__('AddPasskey|Passkey name is required.'))],
          inputAttrs: {
            name: 'device_registration[name]',
            required: true,
            placeholder: __('Macbook Touch ID on Edge'),
            'data-testid': 'device-name-input',
          },
        },
      };

      if (this.passwordRequired) {
        return {
          password: {
            label: __('Current password'),
            groupAttrs: {
              description: s__('AddPasskey|Verify your password to add the passkey'),
            },
            validators: [requiredNonBlank(__('Current password is required.'))],
          },
          ...deviceNameField,
        };
      }

      return deviceNameField;
    },
  },
  created() {
    if (this.initialError) {
      this.setDangerAlert(this.initialError);
    } else if (supported()) {
      this.onRegister();
    } else {
      const message = isSecureContext()
        ? s__("AddPasskey|Your browser doesn't support passkeys.")
        : s__(
            'AddPasskey|Passkeys only works with HTTPS-enabled websites. Contact your administrator for more details.',
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
    onSubmit(event) {
      event.target.submit();
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
      <gl-form :id="$options.formId" method="post" :action="path" novalidate class="gl-col-5">
        <gl-form-fields
          v-model="formFieldsValues"
          :form-id="$options.formId"
          :fields="fields"
          :validate-on-blur="false"
          @submit="onSubmit"
        >
          <template #input(password)="{ id, validation, value, input }">
            <gl-form-password-input
              :id="id"
              :value="value"
              :state="validation.state"
              name="current_password"
              required
              autocomplete="current-password"
              data-testid="current-password-input"
              @input="input"
            />
          </template>
        </gl-form-fields>

        <input type="hidden" name="device_registration[device_response]" :value="credentials" />
        <input type="hidden" name="authenticity_token" :value="$options.csrfToken" />

        <div class="gl-flex gl-gap-3">
          <gl-button type="submit" variant="confirm">{{ s__('AddPasskey|Add passkey') }}</gl-button>
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
