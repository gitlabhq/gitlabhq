<script>
import { s__ } from '~/locale';

import { GITLAB_COM_BASE_PATH } from '~/jira_connect/subscriptions/constants';
import SubscriptionsList from '../../components/subscriptions_list.vue';

export default {
  name: 'SignInGitlabCom',
  components: {
    SubscriptionsList,
    SignInOauthButton: () => import('../../components/sign_in_oauth_button.vue'),
  },
  props: {
    hasSubscriptions: {
      type: Boolean,
      required: true,
    },
  },
  i18n: {
    signInButtonTextWithSubscriptions: s__('JiraConnect|Sign in to link groups'),
    signInText: s__('JiraConnect|Sign in to GitLab to get started.'),
  },
  GITLAB_COM_BASE_PATH,
  methods: {
    onSignInError() {
      this.$emit('error');
    },
  },
};
</script>

<template>
  <div>
    <h2 class="gl-mb-7 gl-text-center">{{ s__('JiraConnect|GitLab for Jira Configuration') }}</h2>
    <div v-if="hasSubscriptions">
      <div class="gl-mb-3 gl-flex gl-justify-end">
        <sign-in-oauth-button
          :gitlab-base-path="$options.GITLAB_COM_BASE_PATH"
          @sign-in="$emit('sign-in-oauth', $event)"
          @error="onSignInError"
        >
          {{ $options.i18n.signInButtonTextWithSubscriptions }}
        </sign-in-oauth-button>
      </div>

      <subscriptions-list />
    </div>
    <div v-else class="gl-text-center">
      <p class="gl-mb-7">{{ $options.i18n.signInText }}</p>
      <sign-in-oauth-button
        :gitlab-base-path="$options.GITLAB_COM_BASE_PATH"
        @sign-in="$emit('sign-in-oauth', $event)"
        @error="onSignInError"
      />
    </div>
  </div>
</template>
