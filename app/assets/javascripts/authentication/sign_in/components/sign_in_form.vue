<script>
import { GlForm, GlFormFields, GlButton, GlFormCheckbox, GlLink } from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/src/utils';
import { __ } from '~/locale';
import csrf from '~/lib/utils/csrf';
import { initRecaptchaScript } from '~/captcha/init_recaptcha_script';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import PasswordInput from '~/authentication/password/components/password_input.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { setUrlFragment, visitUrl, mergeUrlParams } from '~/lib/utils/url_utility';
import axios from '~/lib/utils/axios_utils';

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
  mixins: [glFeatureFlagsMixin()],
  props: {
    railsFields: {
      type: Object,
      required: true,
    },
    signInPath: {
      type: String,
      required: true,
    },
    usersSignInPathPath: {
      type: String,
      required: true,
    },
    passkeysSignInPath: {
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
    isRememberMeEnabled: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      formFieldsValues: {
        login: this.railsFields.login.value,
        password: this.railsFields.password.value,
      },
      rememberMe: this.railsFields.rememberMe.value || '0',
      isSubmitDisabled: false,
      showPasswordField: true,
      loading: false,
    };
  },
  computed: {
    passwordNameAttr() {
      return this.railsFields.password.name;
    },
    rememberMeNameAttr() {
      return this.railsFields.rememberMe.name;
    },
    loginFieldAutofocusAttr() {
      if (this.isTwoStepSignInEnabled) {
        return !this.showPasswordField;
      }

      return !this.railsFields.login.value;
    },
    passwordFieldAutofocusAttr() {
      return !this.loginFieldAutofocusAttr;
    },
    fields() {
      const baseFields = {
        login: {
          id: this.railsFields.login.id,
          label: __('Username or primary email'),
          validators: [formValidators.required(__('Username or primary email is required.'))],
          inputAttrs: {
            name: this.railsFields.login.name,
            autofocus: this.loginFieldAutofocusAttr,
            autocomplete: 'username',
            autocapitalize: 'off',
            autocorrect: 'off',
            required: true,
            'data-testid': 'username-field',
          },
        },
      };

      if (this.showPasswordField) {
        return {
          ...baseFields,
          password: {
            id: this.railsFields.password.id,
            label: __('Password'),
            validators: [formValidators.required(__('Password is required.'))],
          },
        };
      }

      return baseFields;
    },
    isPasskeysEnabled() {
      return this.glFeatures.passkeys ?? false;
    },
    formAction() {
      return this.addUrlFragment(this.signInPath);
    },
    submitButtonText() {
      return this.showPasswordField ? __('Sign in') : __('Continue');
    },
    isTwoStepSignInEnabled() {
      return this.glFeatures.twoStepSignIn;
    },
  },
  created() {
    this.setInitialShowPasswordFieldValue();
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
    setInitialShowPasswordFieldValue() {
      const isLoginPrefilled = Boolean(this.formFieldsValues.login);

      this.showPasswordField = !this.isTwoStepSignInEnabled || isLoginPrefilled;
    },
    addUrlFragment(signInPath) {
      const fragment = document.location.hash;

      if (!fragment) {
        return signInPath;
      }

      return setUrlFragment(signInPath, fragment);
    },
    redirectPath(signInPath, urlParams = {}) {
      const computedUrlParams =
        this.rememberMe === '1' ? { ...urlParams, remember_me: this.rememberMe } : urlParams;
      const url = this.addUrlFragment(signInPath);

      return mergeUrlParams(computedUrlParams, url);
    },
    onSubmit(event) {
      if (this.isTwoStepSignInEnabled && !this.showPasswordField) {
        this.checkUsernameOrPrimaryEmail();

        return;
      }

      this.isSubmitDisabled = true;
      event.target.submit();
    },
    async checkUsernameOrPrimaryEmail() {
      this.loading = true;

      try {
        const {
          data: { sign_in_path: signInPath },
        } = await axios.get(this.usersSignInPathPath, {
          params: { login: this.formFieldsValues.login },
        });

        if (signInPath === null) {
          // User is found on the current cell
          // Show and focus password field
          this.showPasswordField = true;
        } else {
          // User is not found on the current cell, redirect to the sign in path so user is routed to correct cell
          visitUrl(this.redirectPath(signInPath));
        }
      } catch (error) {
        // There was an error fetching the sign in path
        // Navigate to `/users/sign_in?login=foo@bar.com`
        // If the user exists this will route them to the correct cell
        visitUrl(this.redirectPath(this.signInPath, { login: this.formFieldsValues.login }));
        Sentry.captureException(error);
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-form
      :id="$options.formId"
      :action="formAction"
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
        <template #input(password)="{ id, validation, value, input }">
          <password-input
            :id="id"
            :value="value"
            :state="validation.state"
            :name="passwordNameAttr"
            :autofocus="passwordFieldAutofocusAttr"
            testid="password-field"
            @input="input"
          />
        </template>
      </gl-form-fields>

      <div
        v-if="showCaptcha"
        ref="captcha"
        class="gl-mb-5 gl-flex gl-justify-center"
        data-testid="captcha-el"
      ></div>

      <div v-if="isRememberMeEnabled" class="gl-mb-3">
        <input type="hidden" :name="rememberMeNameAttr" :value="rememberMe" />
        <gl-form-checkbox
          id="user_remember_me"
          v-model="rememberMe"
          value="1"
          unchecked-value="0"
          autocomplete="off"
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
        :loading="loading"
        >{{ submitButtonText }}</gl-button
      >
    </gl-form>
    <gl-form
      v-if="isPasskeysEnabled && showPasswordField"
      :action="passkeysSignInPath"
      method="post"
      class="gl-mt-3"
      data-testid="passkey-form"
    >
      <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
      <input type="hidden" name="remember_me" :value="rememberMe" />
      <gl-button icon="passkey" type="submit" block data-testid="passkey-login-button">{{
        s__('PasskeyAuthentication|Passkey')
      }}</gl-button>
    </gl-form>
  </div>
</template>
