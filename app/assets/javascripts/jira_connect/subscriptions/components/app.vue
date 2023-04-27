<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapState, mapMutations, mapActions } from 'vuex';
import { retrieveAlert } from '~/jira_connect/subscriptions/utils';
import AccessorUtilities from '~/lib/utils/accessor';
import { I18N_DEFAULT_SIGN_IN_ERROR_MESSAGE } from '../constants';
import { SET_ALERT } from '../store/mutation_types';
import SignInPage from '../pages/sign_in/sign_in_page.vue';
import SubscriptionsPage from '../pages/subscriptions_page.vue';
import UserLink from './user_link.vue';
import BrowserSupportAlert from './browser_support_alert.vue';

export default {
  name: 'JiraConnectApp',
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
    BrowserSupportAlert,
    SignInPage,
    SubscriptionsPage,
    UserLink,
  },
  inject: {
    subscriptionsPath: {
      default: '',
    },
    publicKeyStorageEnabled: {
      default: false,
    },
  },
  computed: {
    ...mapState(['currentUser']),
    ...mapState(['alert', 'subscriptions']),
    shouldShowAlert() {
      return Boolean(this.alert?.message);
    },
    hasSubscriptions() {
      return !isEmpty(this.subscriptions);
    },
    userSignedIn() {
      return Boolean(this.currentUser);
    },
    /**
     * Returns false if the GitLab for Jira app doesn't support the user's browser.
     * Any web API that the GitLab for Jira app depends on should be checked here.
     */
    isBrowserSupported() {
      return AccessorUtilities.canUseCrypto();
    },
    gitlabUrl() {
      return gon.gitlab_url;
    },
    gitlabLogo() {
      return gon.gitlab_logo;
    },
  },
  created() {
    this.setInitialAlert();
  },
  mounted() {
    this.fetchSubscriptionsOauth();
  },
  methods: {
    ...mapMutations({
      setAlert: SET_ALERT,
    }),
    ...mapActions(['fetchSubscriptions']),
    /**
     * Fetch subscriptions from the REST API.
     */
    fetchSubscriptionsOauth() {
      if (!this.userSignedIn) return;

      this.fetchSubscriptions(this.subscriptionsPath);
    },
    setInitialAlert() {
      const { linkUrl, title, message, variant } = retrieveAlert() || {};
      this.setAlert({ linkUrl, title, message, variant });
    },
    onSignInOauth() {
      this.fetchSubscriptionsOauth();
    },
    onSignInError() {
      this.setAlert({
        message: I18N_DEFAULT_SIGN_IN_ERROR_MESSAGE,
        variant: 'danger',
      });
    },
  },
};
</script>

<template>
  <div>
    <header
      class="jira-connect-header gl-display-flex gl-align-items-center gl-justify-content-center gl-px-5 gl-border-b-solid gl-border-b-gray-100 gl-border-b-1 gl-bg-white"
    >
      <gl-link :href="gitlabUrl" target="_blank">
        <img :src="gitlabLogo" class="gl-h-6" :alt="__('GitLab')" />
      </gl-link>
      <user-link
        :user-signed-in="userSignedIn"
        :has-subscriptions="hasSubscriptions"
        :user="currentUser"
        class="gl-fixed gl-right-4"
      />
    </header>

    <main class="jira-connect-app gl-px-5 gl-pt-7 gl-mx-auto">
      <browser-support-alert v-if="!isBrowserSupported" class="gl-mb-7" />
      <div v-else data-testid="jira-connect-app">
        <gl-alert
          v-if="shouldShowAlert"
          :variant="alert.variant"
          :title="alert.title"
          class="gl-mb-5"
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

        <div class="gl-layout-w-limited gl-mx-auto gl-px-5 gl-mb-7">
          <sign-in-page
            v-show="!userSignedIn"
            :has-subscriptions="hasSubscriptions"
            :public-key-storage-enabled="publicKeyStorageEnabled"
            @sign-in-oauth="onSignInOauth"
            @error="onSignInError"
          />
          <subscriptions-page v-if="userSignedIn" :has-subscriptions="hasSubscriptions" />
        </div>
      </div>
    </main>
  </div>
</template>
