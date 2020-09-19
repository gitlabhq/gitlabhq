<script>
import { GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { __, sprintf } from '~/locale';

export default {
  directives: {
    SafeHtml,
  },
  computed: {
    ...mapGetters(['getNotesDataByProp']),
    registerLink() {
      return this.getNotesDataByProp('registerPath');
    },
    signInLink() {
      return this.getNotesDataByProp('newSessionPath');
    },
    signedOutText() {
      return sprintf(
        __(
          'Please %{startTagRegister}register%{endRegisterTag} or %{startTagSignIn}sign in%{endSignInTag} to reply',
        ),
        {
          startTagRegister: `<a href="${this.registerLink}">`,
          startTagSignIn: `<a href="${this.signInLink}">`,
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
  <div v-safe-html="signedOutText" class="disabled-comment text-center"></div>
</template>
