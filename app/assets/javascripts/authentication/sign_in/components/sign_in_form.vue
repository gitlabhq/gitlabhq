<script>
import { GlForm, GlFormFields, GlButton, GlFormCheckbox, GlLink } from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/src/utils';
import { __ } from '~/locale';
import csrf from '~/lib/utils/csrf';
import { initRecaptchaScript } from '~/captcha/init_recaptcha_script';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import PasswordInput from '~/authentication/password/components/password_input.vue';
import { FORM_FIELD_LOGIN, FORM_FIELD_PASSWORD, FORM_FIELD_REMEMBER_ME } from '../constants';

export default {
  name: 'SignInForm',
  csrf,
  formId: 'sign-in-form',
  components: {
    GlForm,
    GlFormFields,
    GlButton,
    GlFormCheckbox,
    GlLink,
    PasswordInput,
  },
  props: {
    railsFields: {
      type: Object,
      required: true,
    },
    signInPath: {
      type: String,
      required: true,
    },
    isUnconfirmedEmail: {
      type: Boolean,
      required: true,
    },
    newUserConfirmationPath: {
      type: String,
      required: true,
    },
    newPasswordPath: {
      type: String,
      required: true,
    },
    showCaptcha: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      formFieldsValues: {
        [FORM_FIELD_LOGIN]: this.railsFields[FORM_FIELD_LOGIN].value,
        [FORM_FIELD_PASSWORD]: this.railsFields[FORM_FIELD_PASSWORD].value,
      },
      [FORM_FIELD_REMEMBER_ME]: this.railsFields[FORM_FIELD_REMEMBER_ME].value,
      isSubmitDisabled: false,
    };
  },
  computed: {
    passwordNameAttr() {
      return this.railsFields[FORM_FIELD_PASSWORD].name;
    },
    rememberMeNameAttr() {
      return this.railsFields[FORM_FIELD_REMEMBER_ME].name;
    },
    fields() {
      return {
        [FORM_FIELD_LOGIN]: {
          id: this.railsFields[FORM_FIELD_LOGIN].id,
          label: __('Username or primary email'),
          validators: [formValidators.required(__('Username or primary email is required.'))],
          inputAttrs: {
            name: this.railsFields[FORM_FIELD_LOGIN].name,
            autofocus: true,
            autocomplete: 'username',
            autocapitalize: 'off',
            autocorrect: 'off',
            required: true,
            'data-testid': 'username-field',
          },
        },
        [FORM_FIELD_PASSWORD]: {
          id: this.railsFields[FORM_FIELD_PASSWORD].id,
          label: __('Password'),
          validators: [formValidators.required(__('Password is required.'))],
        },
      };
    },
  },
  async mounted() {
    if (!this.showCaptcha) return;

    try {
      const grecaptcha = await initRecaptchaScript();

      grecaptcha.render(this.$refs.captcha, {
        sitekey: window.gon?.recaptcha_sitekey,
      });
    } catch (error) {
      Sentry.captureException(error);
    }
  },
  methods: {
    onSubmit(event) {
      this.isSubmitDisabled = true;
      event.target.submit();
    },
  },
};
</script>

<template>
  <gl-form
    :id="$options.formId"
    :action="signInPath"
    method="post"
    aria-live="assertive"
    novalidate
    data-testid="sign-in-form"
  >
    <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
    <gl-form-fields
      v-model="formFieldsValues"
      :form-id="$options.formId"
      :fields="fields"
      :validate-on-blur="false"
      @submit="onSubmit"
    >
      <template #group(password)-description>
        <div class="gl-text-right">
          <gl-link v-if="isUnconfirmedEmail" :href="newUserConfirmationPath">{{
            __('Resend confirmation email')
          }}</gl-link>
          <gl-link v-else :href="newPasswordPath">{{ __('Forgot your password?') }}</gl-link>
        </div>
      </template>
      <template #input(password)="{ id, validation, value, input, blur }">
        <password-input
          :id="id"
          :value="value"
          :state="validation.state"
          :name="passwordNameAttr"
          testid="password-field"
          @input="input"
          @blur="blur"
        />
      </template>
    </gl-form-fields>

    <div
      v-if="showCaptcha"
      ref="captcha"
      class="gl-mb-5 gl-flex gl-justify-center"
      data-testid="captcha-el"
    ></div>

    <div class="gl-mb-5">
      <!-- Unchecked checkboxes do not send a value with the form submission -->
      <!-- This ensures that when the "Remember me" checkbox is unchecked we send a value of 0 -->
      <!-- When the "Remember me" checkbox is checked the value of the checkbox overrides this hidden input -->
      <input type="hidden" :name="rememberMeNameAttr" value="0" />
      <gl-form-checkbox
        v-model="rememberMe"
        :name="rememberMeNameAttr"
        value="1"
        unchecked-value="0"
      >
        {{ __('Remember me') }}
      </gl-form-checkbox>
    </div>
    <gl-button
      type="submit"
      variant="confirm"
      class="js-no-auto-disable"
      data-testid="sign-in-button"
      block
      :disabled="isSubmitDisabled"
      >{{ __('Sign in') }}</gl-button
    >
  </gl-form>
</template>
