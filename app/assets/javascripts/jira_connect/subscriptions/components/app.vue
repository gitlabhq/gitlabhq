<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapState, mapMutations } from 'vuex';
import { retrieveAlert } from '~/jira_connect/subscriptions/utils';
import { SET_ALERT } from '../store/mutation_types';
import SignInPage from '../pages/sign_in.vue';
import SubscriptionsPage from '../pages/subscriptions.vue';
import UserLink from './user_link.vue';
import CompatibilityAlert from './compatibility_alert.vue';

export default {
  name: 'JiraConnectApp',
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
    UserLink,
    CompatibilityAlert,
    SignInPage,
    SubscriptionsPage,
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
    <div class="gl-layout-w-limited gl-mx-auto gl-px-5 gl-mb-7">
      <sign-in-page v-if="!userSignedIn" :has-subscriptions="hasSubscriptions" />
      <subscriptions-page v-else :has-subscriptions="hasSubscriptions" />
    </div>
  </div>
</template>
