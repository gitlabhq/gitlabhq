<script>
import { GlButton, GlForm, GlFormFields, GlLink, GlSprintf } from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/src/utils';
import illustration from '@gitlab/svgs/dist/illustrations/empty-state/empty-secrets-md.svg?url';
import csrf from '~/lib/utils/csrf';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { newAdminSessionPath } from '~/lib/utils/path_helpers/admin';
import { newUserSessionPath } from '~/lib/utils/path_helpers/routes';
import VerificationLayout from './verification_layout.vue';

export default {
  name: 'RecoveryCode',
  components: {
    GlButton,
    GlForm,
    GlFormFields,
    GlLink,
    GlSprintf,
    VerificationLayout,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
    adminMode: {
      type: Boolean,
      required: false,
      default: false,
    },
    rememberMe: {
      type: String,
      required: true,
    },
    rememberMeEnabled: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return { values: { otpAttempt: '' } };
  },
  methods: {
    newUserSessionPath,
    newAdminSessionPath,
  },
  csrf,
  illustration,
  recoveryCodesHelpPath: helpPagePath('user/profile/account/two_factor_authentication', {
    anchor: 'recovery-codes',
  }),
  sshHelpPath: helpPagePath('user/profile/account/two_factor_authentication_troubleshooting', {
    anchor: 'regenerate-recovery-codes-with-ssh',
  }),
  fields: {
    otpAttempt: {
      // Intentionally no otp-named id here: an otp-flavored id prompts password managers to
      // autofill OTP codes into the recovery field. The name stays user[otp_attempt] (the
      // backend param) until it is renamed in
      // https://gitlab.com/gitlab-org/gitlab/-/work_items/579319
      label: s__('TwoFactorAuth|Recovery code'),
      validators: [formValidators.required(s__('TwoFactorAuth|Recovery code is required.'))],
      inputAttrs: {
        autocomplete: 'off',
        autofocus: true,
        'data-testid': 'recovery-code-field',
        name: 'user[otp_attempt]',
      },
    },
  },
};
</script>

<template>
  <verification-layout
    :svg-path="$options.illustration"
    :title="s__('TwoFactorAuth|Enter account recovery code')"
  >
    <template #description>
      <gl-sprintf
        :message="
          s__(
            'TwoFactorAuth|Enter one of the %{linkStart}recovery codes%{linkEnd} generated when you added two-factor authentication to your account.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="$options.recoveryCodesHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>

    <gl-form id="recovery-form" ref="form" :action="path" method="post">
      <gl-form-fields
        v-model="values"
        form-id="recovery-form"
        :fields="$options.fields"
        :validate-on-blur="false"
        @submit="$refs.form.$el.submit()"
      />

      <input v-if="rememberMeEnabled" type="hidden" name="user[remember_me]" :value="rememberMe" />
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
      <input type="hidden" name="two_factor_method" value="recovery" />

      <div class="gl-flex gl-flex-col gl-gap-3">
        <gl-button
          block
          class="js-no-auto-disable"
          data-testid="verify-recovery-code-button"
          type="submit"
          variant="confirm"
          >{{ s__('TwoFactorAuth|Verify code') }}</gl-button
        >
        <gl-button
          block
          :href="adminMode ? newAdminSessionPath() : newUserSessionPath()"
          data-testid="back-to-sign-in-button"
          >{{ s__('TwoFactorAuth|Back to sign-in') }}</gl-button
        >
      </div>
    </gl-form>

    <p class="gl-mt-5 gl-text-subtle">
      <gl-sprintf
        :message="
          s__(
            'TwoFactorAuth|Lost your codes? %{linkStart}Generate recovery codes with SSH key%{linkEnd}',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="$options.sshHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
  </verification-layout>
</template>
