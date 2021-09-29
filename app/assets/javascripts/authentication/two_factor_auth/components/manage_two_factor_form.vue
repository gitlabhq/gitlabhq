<script>
import { GlFormInput, GlFormGroup, GlButton, GlForm } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { __ } from '~/locale';

export const i18n = {
  currentPassword: __('Current password'),
  confirmWebAuthn: __(
    'Are you sure? This will invalidate your registered applications and U2F / WebAuthn devices.',
  ),
  confirm: __('Are you sure? This will invalidate your registered applications and U2F devices.'),
  disableTwoFactor: __('Disable two-factor authentication'),
  regenerateRecoveryCodes: __('Regenerate recovery codes'),
};

export default {
  name: 'ManageTwoFactorForm',
  i18n,
  components: {
    GlForm,
    GlFormInput,
    GlFormGroup,
    GlButton,
  },
  inject: [
    'webauthnEnabled',
    'profileTwoFactorAuthPath',
    'profileTwoFactorAuthMethod',
    'codesProfileTwoFactorAuthPath',
    'codesProfileTwoFactorAuthMethod',
  ],
  data() {
    return {
      method: '',
      action: '#',
    };
  },
  computed: {
    confirmText() {
      if (this.webauthnEnabled) {
        return i18n.confirmWebAuthn;
      }

      return i18n.confirm;
    },
  },
  methods: {
    handleFormSubmit(event) {
      this.method = event.submitter.dataset.formMethod;
      this.action = event.submitter.dataset.formAction;
    },
  },
  csrf,
};
</script>

<template>
  <gl-form
    class="gl-display-inline-block"
    method="post"
    :action="action"
    @submit="handleFormSubmit($event)"
  >
    <input type="hidden" name="_method" data-testid="test-2fa-method-field" :value="method" />
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />

    <gl-form-group :label="$options.i18n.currentPassword" label-for="current-password">
      <gl-form-input
        id="current-password"
        type="password"
        name="current_password"
        required
        data-qa-selector="current_password_field"
      />
    </gl-form-group>

    <gl-button
      type="submit"
      class="btn-danger gl-mr-3 gl-display-inline-block"
      data-testid="test-2fa-disable-button"
      variant="danger"
      :data-confirm="confirmText"
      :data-form-action="profileTwoFactorAuthPath"
      :data-form-method="profileTwoFactorAuthMethod"
    >
      {{ $options.i18n.disableTwoFactor }}
    </gl-button>
    <gl-button
      type="submit"
      class="gl-display-inline-block"
      data-testid="test-2fa-regenerate-codes-button"
      :data-form-action="codesProfileTwoFactorAuthPath"
      :data-form-method="codesProfileTwoFactorAuthMethod"
    >
      {{ $options.i18n.regenerateRecoveryCodes }}
    </gl-button>
  </gl-form>
</template>
