<script>
import {
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInputGroup,
  GlFormInput,
  GlLink,
  GlFormSelect,
  GlSprintf,
} from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  isEmptyValue,
  hasMinimumLength,
  isIntegerGreaterThan,
  isServiceDeskSettingEmail,
} from '~/lib/utils/forms';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import {
  I18N_FORM_INTRODUCTION_PARAGRAPH,
  I18N_FORM_CUSTOM_EMAIL_LABEL,
  I18N_FORM_CUSTOM_EMAIL_DESCRIPTION,
  I18N_FORM_FORWARDING_LABEL,
  I18N_FORM_FORWARDING_CLIPBOARD_BUTTON_TITLE,
  I18N_FORM_SMTP_ADDRESS_LABEL,
  I18N_FORM_SMTP_PORT_LABEL,
  I18N_FORM_SMTP_PORT_DESCRIPTION,
  I18N_FORM_SMTP_USERNAME_LABEL,
  I18N_FORM_SMTP_PASSWORD_LABEL,
  I18N_FORM_SMTP_PASSWORD_DESCRIPTION,
  I18N_FORM_SMTP_AUTHENTICATION_LABEL,
  I18N_FORM_SMTP_AUTHENTICATION_NONE,
  I18N_FORM_SMTP_AUTHENTICATION_PLAIN,
  I18N_FORM_SMTP_AUTHENTICATION_LOGIN,
  I18N_FORM_SMTP_AUTHENTICATION_CRAM_MD5,
  I18N_FORM_SUBMIT_LABEL,
  I18N_FORM_INVALID_FEEDBACK_CUSTOM_EMAIL,
  I18N_FORM_INVALID_FEEDBACK_SMTP_ADDRESS,
  I18N_FORM_INVALID_FEEDBACK_SMTP_PORT,
  I18N_FORM_INVALID_FEEDBACK_SMTP_USERNAME,
  I18N_FORM_INVALID_FEEDBACK_SMTP_PASSWORD,
} from '../custom_email_constants';

export default {
  customEmailHelpUrl: helpPagePath('user/project/service_desk/configure.html', {
    anchor: 'custom-email-address',
  }),
  components: {
    ClipboardButton,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInputGroup,
    GlFormInput,
    GlFormSelect,
    GlLink,
    GlSprintf,
  },
  I18N_FORM_INTRODUCTION_PARAGRAPH,
  I18N_FORM_CUSTOM_EMAIL_LABEL,
  I18N_FORM_CUSTOM_EMAIL_DESCRIPTION,
  I18N_FORM_FORWARDING_LABEL,
  I18N_FORM_FORWARDING_CLIPBOARD_BUTTON_TITLE,
  I18N_FORM_SMTP_ADDRESS_LABEL,
  I18N_FORM_SMTP_PORT_LABEL,
  I18N_FORM_SMTP_PORT_DESCRIPTION,
  I18N_FORM_SMTP_USERNAME_LABEL,
  I18N_FORM_SMTP_PASSWORD_LABEL,
  I18N_FORM_SMTP_PASSWORD_DESCRIPTION,
  I18N_FORM_SMTP_AUTHENTICATION_LABEL,
  I18N_FORM_SMTP_AUTHENTICATION_NONE,
  I18N_FORM_SMTP_AUTHENTICATION_PLAIN,
  I18N_FORM_SMTP_AUTHENTICATION_LOGIN,
  I18N_FORM_SMTP_AUTHENTICATION_CRAM_MD5,
  I18N_FORM_SUBMIT_LABEL,
  I18N_FORM_INVALID_FEEDBACK_CUSTOM_EMAIL,
  I18N_FORM_INVALID_FEEDBACK_SMTP_ADDRESS,
  I18N_FORM_INVALID_FEEDBACK_SMTP_PORT,
  I18N_FORM_INVALID_FEEDBACK_SMTP_USERNAME,
  I18N_FORM_INVALID_FEEDBACK_SMTP_PASSWORD,
  props: {
    incomingEmail: {
      type: String,
      required: false,
      default: '',
    },
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      customEmail: '',
      forwardingConfigured: false,
      smtpAddress: '',
      smtpPort: '587',
      smtpUsername: '',
      smtpPassword: '',
      smtpAuthentication: null,
      validationState: {
        customEmail: null,
        smtpAddress: null,
        smtpPort: true,
        smtpUsername: null,
        smtpPassword: null,
      },
    };
  },
  computed: {
    isFormValid() {
      return Object.values(this.validationState).every(Boolean);
    },
  },
  methods: {
    onSubmit() {
      this.triggerVerification();

      if (!this.isFormValid) {
        return;
      }

      this.$emit('submit', this.getRequestFormData());
    },
    getRequestFormData() {
      return {
        custom_email: this.customEmail,
        smtp_address: this.smtpAddress,
        smtp_port: this.smtpPort,
        smtp_username: this.smtpUsername,
        smtp_password: this.smtpPassword,
        smtp_authentication: this.smtpAuthentication,
      };
    },
    onCustomEmailChange() {
      this.validateCustomEmail();

      if (this.validationState.customEmail && isEmptyValue(this.smtpUsername)) {
        this.smtpUsername = this.customEmail;
        this.validateSmtpUsername();
      }
    },
    validateCustomEmail() {
      this.validationState.customEmail = isServiceDeskSettingEmail(this.customEmail);
    },
    validateSmtpAddress() {
      this.validationState.smtpAddress = !isEmptyValue(this.smtpAddress);
    },
    validateSmtpPort() {
      this.validationState.smtpPort = isIntegerGreaterThan(this.smtpPort, 0);
    },
    validateSmtpUsername() {
      this.validationState.smtpUsername = !isEmptyValue(this.smtpUsername);
    },
    validateSmtpPassword() {
      this.validationState.smtpPassword = hasMinimumLength(this.smtpPassword, 8);
    },
    triggerVerification() {
      this.validateCustomEmail();
      this.validateSmtpAddress();
      this.validateSmtpPort();
      this.validateSmtpUsername();
      this.validateSmtpPassword();
    },
    getSmtpAuthenticationOptions() {
      return [
        {
          text: this.$options.I18N_FORM_SMTP_AUTHENTICATION_NONE,
          value: null,
        },
        {
          text: this.$options.I18N_FORM_SMTP_AUTHENTICATION_PLAIN,
          value: 'plain',
        },
        {
          text: this.$options.I18N_FORM_SMTP_AUTHENTICATION_LOGIN,
          value: 'login',
        },
        {
          text: this.$options.I18N_FORM_SMTP_AUTHENTICATION_CRAM_MD5,
          value: 'cram_md5',
        },
      ];
    },
  },
};
</script>

<template>
  <div>
    <p>
      <gl-sprintf :message="$options.I18N_FORM_INTRODUCTION_PARAGRAPH">
        <template #link="{ content }">
          <gl-link :href="$options.customEmailHelpUrl" class="gl-inline-block" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </p>
    <gl-form class="js-quick-submit" @submit.prevent="onSubmit">
      <gl-form-group
        :label="$options.I18N_FORM_FORWARDING_LABEL"
        label-for="custom-email-form-forwarding"
        class="gl-mt-3"
      >
        <gl-form-input-group>
          <gl-form-input
            id="custom-email-form-forwarding"
            ref="service-desk-incoming-email"
            type="text"
            :aria-label="$options.I18N_FORM_FORWARDING_LABEL"
            :value="incomingEmail"
            :disabled="true"
          />
          <template #append>
            <clipboard-button
              :title="$options.I18N_FORM_FORWARDING_CLIPBOARD_BUTTON_TITLE"
              :text="incomingEmail"
              css-class="input-group-text"
            />
          </template>
        </gl-form-input-group>
      </gl-form-group>

      <gl-form-group
        :label="$options.I18N_FORM_CUSTOM_EMAIL_LABEL"
        label-for="custom-email-form-custom-email"
        :invalid-feedback="$options.I18N_FORM_INVALID_FEEDBACK_CUSTOM_EMAIL"
        class="gl-mt-3"
        :description="$options.I18N_FORM_CUSTOM_EMAIL_DESCRIPTION"
      >
        <!-- eslint-disable @gitlab/vue-require-i18n-attribute-strings -->
        <gl-form-input
          id="custom-email-form-custom-email"
          v-model.trim="customEmail"
          data-testid="form-custom-email"
          :aria-label="$options.I18N_FORM_CUSTOM_EMAIL_LABEL"
          placeholder="contact@example.com"
          type="email"
          :state="validationState.customEmail"
          :required="true"
          :disabled="isSubmitting"
          @change="onCustomEmailChange"
        />
        <!-- eslint-enable @gitlab/vue-require-i18n-attribute-strings -->
      </gl-form-group>

      <gl-form-group
        :label="$options.I18N_FORM_SMTP_ADDRESS_LABEL"
        label-for="custom-email-form-smtp-address"
        :invalid-feedback="$options.I18N_FORM_INVALID_FEEDBACK_SMTP_ADDRESS"
        class="gl-mt-3"
      >
        <!-- eslint-disable @gitlab/vue-require-i18n-attribute-strings -->
        <gl-form-input
          id="custom-email-form-smtp-address"
          v-model.trim="smtpAddress"
          data-testid="form-smtp-address"
          :aria-label="$options.I18N_FORM_SMTP_ADDRESS_LABEL"
          placeholder="smtp.example.com"
          type="email"
          :state="validationState.smtpAddress"
          :required="true"
          :disabled="isSubmitting"
          @change="validateSmtpAddress"
        />
        <!-- eslint-enable @gitlab/vue-require-i18n-attribute-strings -->
      </gl-form-group>

      <gl-form-group
        :label="$options.I18N_FORM_SMTP_PORT_LABEL"
        label-for="custom-email-form-smtp-port"
        :invalid-feedback="$options.I18N_FORM_INVALID_FEEDBACK_SMTP_PORT"
        class="gl-mt-3"
        :description="$options.I18N_FORM_SMTP_PORT_DESCRIPTION"
      >
        <!-- eslint-disable @gitlab/vue-require-i18n-attribute-strings -->
        <gl-form-input
          id="custom-email-form-smtp-port"
          v-model.trim="smtpPort"
          data-testid="form-smtp-port"
          :aria-label="$options.I18N_FORM_SMTP_PORT_LABEL"
          placeholder="587"
          type="number"
          :state="validationState.smtpPort"
          :required="true"
          :disabled="isSubmitting"
          @change="validateSmtpPort"
        />
        <!-- eslint-enable @gitlab/vue-require-i18n-attribute-strings -->
      </gl-form-group>

      <gl-form-group
        :label="$options.I18N_FORM_SMTP_USERNAME_LABEL"
        label-for="custom-email-form-smtp-username"
        :invalid-feedback="$options.I18N_FORM_INVALID_FEEDBACK_SMTP_USERNAME"
        class="gl-mt-3"
      >
        <!-- eslint-disable @gitlab/vue-require-i18n-attribute-strings -->
        <gl-form-input
          id="custom-email-form-smtp-username"
          v-model.trim="smtpUsername"
          data-testid="form-smtp-username"
          :aria-label="$options.I18N_FORM_SMTP_USERNAME_LABEL"
          placeholder="contact@example.com"
          :state="validationState.smtpUsername"
          :required="true"
          :disabled="isSubmitting"
          @change="validateSmtpUsername"
        />
        <!-- eslint-enable @gitlab/vue-require-i18n-attribute-strings -->
      </gl-form-group>

      <gl-form-group
        :label="$options.I18N_FORM_SMTP_PASSWORD_LABEL"
        label-for="custom-email-form-smtp-password"
        :invalid-feedback="$options.I18N_FORM_INVALID_FEEDBACK_SMTP_PASSWORD"
        class="gl-mt-3"
        :description="$options.I18N_FORM_SMTP_PASSWORD_DESCRIPTION"
      >
        <gl-form-input
          id="custom-email-form-smtp-password"
          v-model.trim="smtpPassword"
          data-testid="form-smtp-password"
          :aria-label="$options.I18N_FORM_SMTP_PASSWORD_LABEL"
          type="password"
          :state="validationState.smtpPassword"
          :required="true"
          :disabled="isSubmitting"
          @change="validateSmtpPassword"
        />
      </gl-form-group>

      <gl-form-group
        :label="$options.I18N_FORM_SMTP_AUTHENTICATION_LABEL"
        label-for="custom-email-form-smtp-password"
        class="gl-mt-3"
      >
        <gl-form-select
          id="custom-email-form-smtp-authentication"
          v-model.trim="smtpAuthentication"
          :options="getSmtpAuthenticationOptions()"
          :aria-label="$options.I18N_FORM_SMTP_AUTHENTICATION_LABEL"
          :disabled="isSubmitting"
        />
      </gl-form-group>

      <gl-button
        type="submit"
        variant="confirm"
        class="gl-mt-5"
        data-testid="form-submit"
        :disabled="!isFormValid"
        :loading="isSubmitting"
        @click="onSubmit"
      >
        {{ $options.I18N_FORM_SUBMIT_LABEL }}
      </gl-button>
    </gl-form>
  </div>
</template>
