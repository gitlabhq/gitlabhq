<script>
import { GlAlert, GlLink, GlSprintf, GlEmptyState } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapState, mapMutations } from 'vuex';
import { retrieveAlert } from '~/jira_connect/subscriptions/utils';
import { SET_ALERT } from '../store/mutation_types';
import SubscriptionsList from './subscriptions_list.vue';
import AddNamespaceButton from './add_namespace_button.vue';
import SignInButton from './sign_in_button.vue';
import UserLink from './user_link.vue';
import CompatibilityAlert from './compatibility_alert.vue';

export default {
  name: 'JiraConnectApp',
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
    GlEmptyState,
    SubscriptionsList,
    AddNamespaceButton,
    SignInButton,
    UserLink,
    CompatibilityAlert,
  },
  inject: {
    usersPath: {
      default: '',
    },
    subscriptions: {
      default: [],
    },
  },
  computed: {
    ...mapState(['alert']),
    shouldShowAlert() {
      return Boolean(this.alert?.message);
    },
    hasSubscriptions() {
      return !isEmpty(this.subscriptions);
    },
    userSignedIn() {
      return Boolean(!this.usersPath);
    },
  },
  created() {
    this.setInitialAlert();
  },
  methods: {
    ...mapMutations({
      setAlert: SET_ALERT,
    }),
    setInitialAlert() {
      const { linkUrl, title, message, variant } = retrieveAlert() || {};
      this.setAlert({ linkUrl, title, message, variant });
    },
  },
};
</script>

<template>
  <div>
    <compatibility-alert />

    <gl-alert
      v-if="shouldShowAlert"
      class="gl-mb-7"
      :variant="alert.variant"
      :title="alert.title"
      data-testid="jira-connect-persisted-alert"
      @dismiss="setAlert"
    >
      <gl-sprintf v-if="alert.linkUrl" :message="alert.message">
        <template #link="{ content }">
          <gl-link :href="alert.linkUrl" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>

      <template v-else>
        {{ alert.message }}
      </template>
    </gl-alert>

    <user-link :user-signed-in="userSignedIn" :has-subscriptions="hasSubscriptions" />

    <h2 class="gl-text-center gl-mb-7">{{ s__('JiraService|GitLab for Jira Configuration') }}</h2>
    <div class="jira-connect-app-body gl-mx-auto gl-px-5 gl-mb-7">
      <template v-if="hasSubscriptions">
        <div class="gl-display-flex gl-justify-content-end">
          <sign-in-button v-if="!userSignedIn" :users-path="usersPath" />
          <add-namespace-button v-else />
        </div>

        <subscriptions-list />
      </template>
      <template v-else>
        <div v-if="!userSignedIn" class="gl-text-center">
          <p class="gl-mb-7">{{ s__('JiraService|Sign in to GitLab.com to get started.') }}</p>
          <sign-in-button class="gl-mb-7" :users-path="usersPath">
            {{ __('Sign in to GitLab') }}
          </sign-in-button>
          <p>
            {{
              s__(
                'Integrations|Note: this integration only works with accounts on GitLab.com (SaaS).',
              )
            }}
          </p>
        </div>
        <gl-empty-state
          v-else
          :title="s__('Integrations|No linked namespaces')"
          :description="
            s__(
              'Integrations|Namespaces are the GitLab groups and subgroups you link to this Jira instance.',
            )
          "
        >
          <template #actions>
            <add-namespace-button />
          </template>
        </gl-empty-state>
      </template>
    </div>
  </div>
</template>
