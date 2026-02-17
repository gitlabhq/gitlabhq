<script>
// eslint-disable-next-line no-restricted-imports
import { mapMutations } from 'vuex';
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';

import { reloadPage, persistBaseUrl, retrieveBaseUrl } from '~/jira_connect/subscriptions/utils';
import { updateInstallation, setApiBaseURL } from '~/jira_connect/subscriptions/api';
import {
  GITLAB_COM_BASE_PATH,
  I18N_UPDATE_INSTALLATION_ERROR_MESSAGE,
  FAILED_TO_UPDATE_DOC_LINK,
} from '~/jira_connect/subscriptions/constants';
import { SET_ALERT } from '~/jira_connect/subscriptions/store/mutation_types';

import SignInOauthButton from '../../../components/sign_in_oauth_button.vue';
import VersionSelectForm from './version_select_form.vue';

export default {
  name: 'SignInGitlabMultiversion',
  components: {
    GlButton,
    SignInOauthButton,
    VersionSelectForm,
  },
  data() {
    return {
      gitlabBasePath: null,
      loadingVersionSelect: false,
    };
  },
  computed: {
    hasSelectedVersion() {
      return this.gitlabBasePath !== null;
    },
  },
  mounted() {
    this.gitlabBasePath = retrieveBaseUrl();
    if (this.gitlabBasePath !== GITLAB_COM_BASE_PATH) {
      setApiBaseURL(this.gitlabBasePath);
    }
  },
  methods: {
    ...mapMutations({
      setAlert: SET_ALERT,
    }),
    resetGitlabBasePath() {
      this.gitlabBasePath = null;
      setApiBaseURL();
    },
    onVersionSelect(gitlabBasePath) {
      this.loadingVersionSelect = true;
      updateInstallation(gitlabBasePath)
        .then(() => {
          persistBaseUrl(gitlabBasePath);
          reloadPage();
        })
        .catch(() => {
          this.setAlert({
            message: I18N_UPDATE_INSTALLATION_ERROR_MESSAGE,
            linkUrl: FAILED_TO_UPDATE_DOC_LINK,
            variant: 'danger',
          });
          this.loadingVersionSelect = false;
        });
    },
    onSignInError() {
      this.$emit('error');
    },
  },
  i18n: {
    title: s__('JiraConnect|Welcome to GitLab for Jira'),
    signInSubtitle: s__('JiraConnect|Sign in to GitLab to link groups.'),
    changeVersionButtonText: s__('JiraConnect|Change GitLab version'),
  },
};
</script>

<template>
  <div>
    <div class="gl-text-center">
      <h2>{{ $options.i18n.title }}</h2>
    </div>

    <version-select-form
      v-if="!hasSelectedVersion"
      class="gl-mt-7"
      :loading="loadingVersionSelect"
      @submit="onVersionSelect"
    />

    <template v-else>
      <div class="gl-text-center">
        <p data-testid="subtitle">{{ $options.i18n.signInSubtitle }}</p>
        <sign-in-oauth-button
          class="gl-mb-5"
          :gitlab-base-path="gitlabBasePath"
          @sign-in="$emit('sign-in-oauth', $event)"
          @error="onSignInError"
        />

        <div>
          <gl-button category="tertiary" variant="confirm" @click="resetGitlabBasePath">
            {{ $options.i18n.changeVersionButtonText }}
          </gl-button>
        </div>
      </div>
    </template>
  </div>
</template>
