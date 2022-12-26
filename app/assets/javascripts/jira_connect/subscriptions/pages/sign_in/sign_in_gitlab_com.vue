<script>
import { s__ } from '~/locale';

import { GITLAB_COM_BASE_PATH } from '~/jira_connect/subscriptions/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import SubscriptionsList from '../../components/subscriptions_list.vue';

export default {
  name: 'SignInGitlabCom',
  components: {
    SubscriptionsList,
    SignInLegacyButton: () => import('../../components/sign_in_legacy_button.vue'),
    SignInOauthButton: () => import('../../components/sign_in_oauth_button.vue'),
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['usersPath'],
  props: {
    hasSubscriptions: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    useSignInOauthButton() {
      return this.glFeatures.jiraConnectOauth;
    },
  },
  i18n: {
    signInButtonTextWithSubscriptions: s__('Integrations|Sign in to add namespaces'),
    signInText: s__('JiraService|Sign in to GitLab.com to get started.'),
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
    <h2 class="gl-text-center gl-mb-7">{{ s__('JiraService|GitLab for Jira Configuration') }}</h2>
    <div v-if="hasSubscriptions">
      <div class="gl-display-flex gl-justify-content-end gl-mb-3">
        <sign-in-oauth-button
          v-if="useSignInOauthButton"
          :gitlab-base-path="$options.GITLAB_COM_BASE_PATH"
          @sign-in="$emit('sign-in-oauth', $event)"
          @error="onSignInError"
        >
          {{ $options.i18n.signInButtonTextWithSubscriptions }}
        </sign-in-oauth-button>
        <sign-in-legacy-button v-else :users-path="usersPath">
          {{ $options.i18n.signInButtonTextWithSubscriptions }}
        </sign-in-legacy-button>
      </div>

      <subscriptions-list />
    </div>
    <div v-else class="gl-text-center">
      <p class="gl-mb-7">{{ $options.i18n.signInText }}</p>
      <sign-in-oauth-button
        v-if="useSignInOauthButton"
        :gitlab-base-path="$options.GITLAB_COM_BASE_PATH"
        @sign-in="$emit('sign-in-oauth', $event)"
        @error="onSignInError"
      />
      <sign-in-legacy-button v-else class="gl-mb-7" :users-path="usersPath" />
    </div>
  </div>
</template>
