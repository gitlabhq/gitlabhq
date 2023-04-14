<script>
import { mapMutations } from 'vuex';
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';

import { reloadPage, persistBaseUrl, retrieveBaseUrl } from '~/jira_connect/subscriptions/utils';
import { updateInstallation, setApiBaseURL } from '~/jira_connect/subscriptions/api';
import {
  GITLAB_COM_BASE_PATH,
  I18N_UPDATE_INSTALLATION_ERROR_MESSAGE,
} from '~/jira_connect/subscriptions/constants';
import { SET_ALERT } from '~/jira_connect/subscriptions/store/mutation_types';

import SignInOauthButton from '../../../components/sign_in_oauth_button.vue';
import SetupInstructions from './setup_instructions.vue';
import VersionSelectForm from './version_select_form.vue';

export default {
  name: 'SignInGitlabMultiversion',
  components: {
    GlButton,
    SignInOauthButton,
    SetupInstructions,
    VersionSelectForm,
  },
  data() {
    return {
      gitlabBasePath: null,
      loadingVersionSelect: false,
      showSetupInstructions: false,
    };
  },
  computed: {
    hasSelectedVersion() {
      return this.gitlabBasePath !== null;
    },
    subtitle() {
      return this.hasSelectedVersion
        ? this.$options.i18n.signInSubtitle
        : this.$options.i18n.versionSelectSubtitle;
    },
  },
  mounted() {
    this.gitlabBasePath = retrieveBaseUrl();
    if (this.gitlabBasePath !== GITLAB_COM_BASE_PATH) {
      setApiBaseURL(this.gitlabBasePath);
      this.showSetupInstructions = true;
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
            variant: 'danger',
          });
          this.loadingVersionSelect = false;
        });
    },
    onSetupNext() {
      this.showSetupInstructions = false;
    },
    onSignInError() {
      this.$emit('error');
    },
  },
  i18n: {
    title: s__('JiraService|Welcome to GitLab for Jira'),
    signInSubtitle: s__('JiraService|Sign in to GitLab to link namespaces.'),
    versionSelectSubtitle: s__('JiraService|What version of GitLab are you using?'),
    changeVersionButtonText: s__('JiraService|Change GitLab version'),
  },
};
</script>

<template>
  <div>
    <div class="gl-text-center">
      <h2>{{ $options.i18n.title }}</h2>
      <p data-testid="subtitle">{{ subtitle }}</p>
    </div>

    <version-select-form
      v-if="!hasSelectedVersion"
      class="gl-mt-7"
      :loading="loadingVersionSelect"
      @submit="onVersionSelect"
    />

    <template v-else>
      <setup-instructions v-if="showSetupInstructions" @next="onSetupNext" />

      <div v-else class="gl-text-center">
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
