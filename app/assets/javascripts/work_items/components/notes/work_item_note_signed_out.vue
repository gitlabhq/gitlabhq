<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import { __, sprintf } from '~/locale';

export default {
  directives: {
    SafeHtml,
  },
  inject: ['registerPath', 'signInPath'],
  computed: {
    signedOutText() {
      return sprintf(
        __(
          'Please %{startTagRegister}register%{endRegisterTag} or %{startTagSignIn}sign in%{endSignInTag} to reply',
        ),
        {
          startTagRegister: `<a href="${this.registerPath}">`,
          startTagSignIn: `<a href="${this.signInPath}">`,
          endRegisterTag: '</a>',
          endSignInTag: '</a>',
        },
        false,
      );
    },
  },
};
</script>

<template>
  <div
    v-safe-html="signedOutText"
    class="disabled-comment gl-relative gl-text-center gl-text-subtle"
  ></div>
</template>
