<script>
import { GlLink, GlButton, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

export default {
  name: 'EmailOtpFallbackFooter',
  components: {
    GlLink,
    GlButton,
    GlSprintf,
  },
  props: {
    sendEmailOtpPath: {
      type: String,
      required: true,
    },
    username: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isSendingEmailOtp: false,
    };
  },
  methods: {
    async sendEmailOtp() {
      this.isSendingEmailOtp = true;

      try {
        await axios.post(this.sendEmailOtpPath, {
          user: { login: this.username },
        });

        document.querySelector('.js-2fa-form').classList.add('hidden');

        this.$emit('success');
      } catch (error) {
        const message = __(
          'Failed to send email OTP. Please try again. If the problem persists, refresh your page or sign in again.',
        );
        const name = error?.message;
        this.$emit('error', { message, name });
      } finally {
        this.isSendingEmailOtp = false;
      }
    },
  },
  recoveryCodeLinkPath: helpPagePath('user/profile/account/two_factor_authentication', {
    anchor: 'recovery-codes',
  }),
};
</script>

<template>
  <div class="gl-mt-3 gl-text-center gl-text-secondary">
    <gl-sprintf
      :message="
        __(
          'Having trouble signing in? %{recoveryCodeLinkStart}Enter recovery code%{recoveryCodeLinkEnd} or %{sendCodeLinkStart}send code to email address%{sendCodeLinkEnd}.',
        )
      "
    >
      <template #recoveryCodeLink>
        <gl-link :href="$options.recoveryCodeLinkPath" target="_blank">
          {{ __('Enter recovery code') }}
        </gl-link>
      </template>
      <template #sendCodeLink="{ content }">
        <gl-button
          variant="link"
          :loading="isSendingEmailOtp"
          :disabled="isSendingEmailOtp"
          category="tertiary"
          data-testid="send-email-otp-link"
          @click="sendEmailOtp"
        >
          {{ content }}
        </gl-button>
      </template>
    </gl-sprintf>
  </div>
</template>
