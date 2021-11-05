<script>
import { GlButton } from '@gitlab/ui';
import { getGitlabSignInURL } from '~/jira_connect/subscriptions/utils';

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
};
</script>
<template>
  <gl-button category="primary" variant="info" :href="signInURL" target="_blank">
    <slot>
      {{ s__('Integrations|Sign in to add namespaces') }}
    </slot>
  </gl-button>
</template>
