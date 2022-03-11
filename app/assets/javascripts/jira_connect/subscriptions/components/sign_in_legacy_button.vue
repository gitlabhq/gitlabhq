<script>
import { GlButton } from '@gitlab/ui';
import { getGitlabSignInURL } from '~/jira_connect/subscriptions/utils';
import { I18N_DEFAULT_SIGN_IN_BUTTON_TEXT } from '~/jira_connect/subscriptions/constants';

export default {
  components: {
    GlButton,
  },
  props: {
    usersPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      signInURL: '',
    };
  },
  created() {
    this.setSignInURL();
  },
  methods: {
    async setSignInURL() {
      this.signInURL = await getGitlabSignInURL(this.usersPath);
    },
  },
  i18n: {
    defaultButtonText: I18N_DEFAULT_SIGN_IN_BUTTON_TEXT,
  },
};
</script>
<template>
  <gl-button category="primary" variant="info" :href="signInURL" target="_blank">
    <slot>
      {{ $options.i18n.defaultButtonText }}
    </slot>
  </gl-button>
</template>
