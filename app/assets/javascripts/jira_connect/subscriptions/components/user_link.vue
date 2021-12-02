<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import { getGitlabSignInURL } from '~/jira_connect/subscriptions/utils';

export default {
  components: {
    GlLink,
    GlSprintf,
  },
  inject: {
    usersPath: {
      default: '',
    },
    gitlabUserPath: {
      default: '',
    },
  },
  props: {
    userSignedIn: {
      type: Boolean,
      required: true,
    },
    hasSubscriptions: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      signInURL: '',
    };
  },
  computed: {
    gitlabUserHandle() {
      return `@${gon.current_username}`;
    },
  },
  async created() {
    this.signInURL = await getGitlabSignInURL(this.usersPath);
  },
  i18n: {
    signInText: __('Sign in to GitLab'),
    signedInAsUserText: __('Signed in to GitLab as %{user_link}'),
  },
};
</script>
<template>
  <div class="jira-connect-user gl-font-base">
    <gl-sprintf v-if="userSignedIn" :message="$options.i18n.signedInAsUserText">
      <template #user_link>
        <gl-link data-testid="gitlab-user-link" :href="gitlabUserPath" target="_blank">
          {{ gitlabUserHandle }}
        </gl-link>
      </template>
    </gl-sprintf>

    <gl-link
      v-else-if="hasSubscriptions"
      data-testid="sign-in-link"
      :href="signInURL"
      target="_blank"
    >
      {{ $options.i18n.signInText }}
    </gl-link>
  </div>
</template>
