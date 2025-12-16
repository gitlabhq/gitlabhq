<script>
import { GlButton, GlFormCheckbox, GlFormGroup, GlModal, GlTooltipDirective } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import PasswordInput from '~/authentication/password/components/password_input.vue';
import csrf from '~/lib/utils/csrf';
import { __ } from '~/locale';

export default {
  name: 'EmailOtpActionConfirm',
  csrf,
  i18n: {
    buttonConfirmText: __('Update email OTP settings'),
  },
  actions: {
    cancel: {
      text: __('Cancel'),
    },
  },
  components: { GlButton, GlFormCheckbox, GlFormGroup, GlModal, PasswordInput },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    helpText: {
      type: String,
      required: true,
      default: '',
    },
    path: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: true,
    },
    emailOtpRequired: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      currentValue: this.emailOtpRequired,
      passwordState: null,
      modalVisible: false,
    };
  },
  computed: {
    modalId() {
      return uniqueId('update-email-otp-');
    },
    actionPrimary() {
      return {
        text: this.$options.i18n.buttonConfirmText,
        attributes: {
          'data-testid': 'email-otp-action-primary',
          variant: 'confirm',
        },
      };
    },
    checkboxValue() {
      return this.currentValue ? '1' : '0';
    },
  },
  methods: {
    showModal() {
      this.modalVisible = true;
    },
    submitForm() {
      if (this.$refs.form.current_password.value.trim() === '') {
        this.passwordState = false;
        return;
      }

      this.$refs.form.submit();
    },
  },
};
</script>

<template>
  <div>
    <gl-modal
      v-model="modalVisible"
      size="sm"
      :title="$options.i18n.buttonConfirmText"
      :modal-id="modalId"
      :action-primary="actionPrimary"
      :action-cancel="$options.actions.cancel"
      @primary.prevent="submitForm"
    >
      <form ref="form" :action="path" method="post">
        <p v-if="emailOtpRequired">
          {{ __('Are you sure you want to disable email OTP? Enter your password to continue.') }}
        </p>
        <p v-else>{{ __('Enter your password to continue.') }}</p>

        <gl-form-group
          label-for="current-password"
          data-testid="email-otp-form-group"
          :label="__('Current password')"
          :state="passwordState"
          :invalid-feedback="__('Please enter your current password.')"
        >
          <password-input id="current-password" name="current_password" />
        </gl-form-group>

        <input type="hidden" name="_method" value="put" />
        <input type="hidden" name="user[email_otp_required_as_boolean]" :value="checkboxValue" />
        <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
      </form>
    </gl-modal>

    <gl-form-group>
      <gl-form-checkbox
        v-model="currentValue"
        data-testid="email-otp-required-as-boolean"
        :checked="currentValue"
        :disabled="disabled"
      >
        {{ __('Enable email OTP') }}
      </gl-form-checkbox>

      <p v-if="helpText" class="help-text">
        {{ helpText }}
      </p>

      <gl-button
        class="gl-mt-4"
        data-testid="email-otp-action-button"
        :disabled="disabled"
        @click="showModal"
      >
        {{ __('Save changes') }}
      </gl-button>
    </gl-form-group>
  </div>
</template>
