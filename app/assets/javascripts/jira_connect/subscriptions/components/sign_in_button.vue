<script>
import { GlButton } from '@gitlab/ui';
import { getGitlabSignInURL } from '~/jira_connect/subscriptions/utils';
import { s__ } from '~/locale';

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
    defaultButtonText: s__('Integrations|Sign in to GitLab'),
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
