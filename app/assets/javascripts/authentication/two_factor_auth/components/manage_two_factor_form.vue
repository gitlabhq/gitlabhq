<script>
import { GlFormInput, GlFormGroup, GlButton, GlForm, GlModal } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { __ } from '~/locale';

export const i18n = {
  currentPassword: __('Current password'),
  confirmTitle: __('Are you sure?'),
  confirmWebAuthn: __('This will invalidate your registered applications and WebAuthn devices.'),
  disableTwoFactor: __('Disable two-factor authentication'),
  disable: __('Disable'),
  cancel: __('Cancel'),
  regenerateRecoveryCodes: __('Regenerate recovery codes'),
  currentPasswordInvalidFeedback: __('Please enter your current password.'),
};

export default {
  name: 'ManageTwoFactorForm',
  i18n,
  modalId: 'manage-two-factor-auth-confirm-modal',
  modalActions: {
    primary: {
      text: i18n.disable,
      attributes: {
        variant: 'danger',
      },
    },
    secondary: {
      text: i18n.cancel,
      attributes: {
        variant: 'default',
      },
    },
  },
  components: {
    GlForm,
    GlFormInput,
    GlFormGroup,
    GlButton,
    GlModal,
  },
  inject: [
    'isCurrentPasswordRequired',
    'profileTwoFactorAuthPath',
    'profileTwoFactorAuthMethod',
    'codesProfileTwoFactorAuthPath',
    'codesProfileTwoFactorAuthMethod',
  ],
  data() {
    return {
      method: null,
      action: null,
      currentPassword: '',
      currentPasswordState: null,
      showConfirmModal: false,
    };
  },
  computed: {
    confirmText() {
      return i18n.confirmWebAuthn;
    },
  },
  methods: {
    submitForm() {
      this.$refs.form.$el.submit();
    },
    async handleSubmitButtonClick({ method, action, confirm = false }) {
      this.method = method;
      this.action = action;

      if (this.isCurrentPasswordRequired && this.currentPassword === '') {
        this.currentPasswordState = false;

        return;
      }

      this.currentPasswordState = null;

      if (confirm) {
        this.showConfirmModal = true;

        return;
      }

      // Wait for form action and method to be updated
      await this.$nextTick();

      this.submitForm();
    },
    handleModalPrimary() {
      this.submitForm();
    },
  },
  csrf,
};
</script>

<template>
  <gl-form
    ref="form"
    class="gl-sm-display-inline-block"
    method="post"
    :action="action"
    @submit.prevent
  >
    <input type="hidden" name="_method" data-testid="test-2fa-method-field" :value="method" />
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />

    <gl-form-group
      v-if="isCurrentPasswordRequired"
      :label="$options.i18n.currentPassword"
      label-for="current-password"
      :state="currentPasswordState"
      :invalid-feedback="$options.i18n.currentPasswordInvalidFeedback"
    >
      <gl-form-input
        id="current-password"
        v-model="currentPassword"
        type="password"
        name="current_password"
        :state="currentPasswordState"
      />
    </gl-form-group>

    <div class="gl-display-flex gl-flex-wrap">
      <gl-button
        type="submit"
        class="gl-sm-mr-3 gl-w-full gl-sm-w-auto"
        data-testid="test-2fa-disable-button"
        variant="danger"
        @click.prevent="
          handleSubmitButtonClick({
            method: profileTwoFactorAuthMethod,
            action: profileTwoFactorAuthPath,
            confirm: true,
          })
        "
      >
        {{ $options.i18n.disableTwoFactor }}
      </gl-button>
      <gl-button
        type="submit"
        class="gl-mt-3 gl-sm-mt-0 gl-w-full gl-sm-w-auto"
        data-testid="test-2fa-regenerate-codes-button"
        @click.prevent="
          handleSubmitButtonClick({
            method: codesProfileTwoFactorAuthMethod,
            action: codesProfileTwoFactorAuthPath,
          })
        "
      >
        {{ $options.i18n.regenerateRecoveryCodes }}
      </gl-button>
    </div>
    <gl-modal
      v-model="showConfirmModal"
      :modal-id="$options.modalId"
      size="sm"
      :title="$options.i18n.confirmTitle"
      :action-primary="$options.modalActions.primary"
      :action-secondary="$options.modalActions.secondary"
      @primary="handleModalPrimary"
    >
      {{ confirmText }}
    </gl-modal>
  </gl-form>
</template>
