<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { mapState, mapMutations } from 'vuex';
import { retrieveAlert } from '~/jira_connect/subscriptions/utils';
import { SET_ALERT } from '../store/mutation_types';
import SubscriptionsList from './subscriptions_list.vue';
import AddNamespaceButton from './add_namespace_button.vue';
import SignInButton from './sign_in_button.vue';

export default {
  name: 'JiraConnectApp',
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
    SubscriptionsList,
    AddNamespaceButton,
    SignInButton,
  },
  inject: {
    usersPath: {
      default: '',
    },
  },
  computed: {
    ...mapState(['alert']),
    shouldShowAlert() {
      return Boolean(this.alert?.message);
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
    <gl-alert
      v-if="shouldShowAlert"
      class="gl-mb-7"
      :variant="alert.variant"
      :title="alert.title"
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

    <h2 class="gl-text-center">{{ s__('JiraService|GitLab for Jira Configuration') }}</h2>

    <div class="jira-connect-app-body gl-my-7 gl-px-5 gl-pb-4">
      <div class="gl-display-flex gl-justify-content-end">
        <sign-in-button v-if="!userSignedIn" :users-path="usersPath" />
        <add-namespace-button v-else />
      </div>

      <subscriptions-list />
    </div>
  </div>
</template>
