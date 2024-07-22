<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapMutations } from 'vuex';
import { GlButton } from '@gitlab/ui';
import { sprintf } from '~/locale';

import {
  GITLAB_COM_BASE_PATH,
  I18N_DEFAULT_SIGN_IN_BUTTON_TEXT,
  I18N_CUSTOM_SIGN_IN_BUTTON_TEXT,
  I18N_OAUTH_APPLICATION_ID_ERROR_MESSAGE,
  I18N_OAUTH_FAILED_TITLE,
  I18N_OAUTH_FAILED_MESSAGE,
  OAUTH_SELF_MANAGED_DOC_LINK,
  OAUTH_WINDOW_OPTIONS,
  OAUTH_CALLBACK_MESSAGE_TYPE,
  PKCE_CODE_CHALLENGE_DIGEST_ALGORITHM,
} from '~/jira_connect/subscriptions/constants';
import { fetchOAuthApplicationId, fetchOAuthToken } from '~/jira_connect/subscriptions/api';
import { setUrlParams } from '~/lib/utils/url_utility';
import AccessorUtilities from '~/lib/utils/accessor';
import { createCodeVerifier, createCodeChallenge } from '../pkce';
import { SET_ACCESS_TOKEN, SET_ALERT } from '../store/mutation_types';

export default {
  components: {
    GlButton,
  },
  inject: ['oauthMetadata'],
  props: {
    gitlabBasePath: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  data() {
    return {
      loading: false,
      codeVerifier: null,
      clientId: null,
      canUseCrypto: AccessorUtilities.canUseCrypto(),
    };
  },
  computed: {
    isGitlabCom() {
      return this.gitlabBasePath === GITLAB_COM_BASE_PATH;
    },
    buttonText() {
      if (this.isGitlabCom) {
        return I18N_DEFAULT_SIGN_IN_BUTTON_TEXT;
      }

      return sprintf(I18N_CUSTOM_SIGN_IN_BUTTON_TEXT, { url: this.gitlabBasePath });
    },
  },
  created() {
    window.addEventListener('message', this.handleWindowMessage);
  },
  beforeDestroy() {
    window.removeEventListener('message', this.handleWindowMessage);
  },
  methods: {
    ...mapActions(['loadCurrentUser']),
    ...mapMutations({
      setAccessToken: SET_ACCESS_TOKEN,
      setAlert: SET_ALERT,
    }),
    async fetchOauthClientId() {
      const {
        data: { application_id: clientId },
      } = await fetchOAuthApplicationId();
      return clientId;
    },
    async getOauthAuthorizeURL() {
      // Generate state necessary for PKCE OAuth flow
      this.codeVerifier = createCodeVerifier();
      const codeChallenge = await createCodeChallenge(this.codeVerifier);
      try {
        this.clientId = this.isGitlabCom
          ? this.oauthMetadata?.oauth_token_payload?.client_id
          : await this.fetchOauthClientId();
      } catch {
        throw new Error(I18N_OAUTH_APPLICATION_ID_ERROR_MESSAGE);
      }

      // Build the initial OAuth authorization URL
      const { oauth_authorize_url: oauthAuthorizeURL } = this.oauthMetadata;
      const oauthAuthorizeURLWithChallenge = new URL(
        setUrlParams(
          {
            code_challenge: codeChallenge,
            code_challenge_method: PKCE_CODE_CHALLENGE_DIGEST_ALGORITHM.short,
            client_id: this.clientId,
          },
          oauthAuthorizeURL,
        ),
      );

      // Rebase URL on the specified GitLab base path (if specified).
      if (!this.isGitlabCom) {
        const gitlabBasePathURL = new URL(this.gitlabBasePath);
        oauthAuthorizeURLWithChallenge.hostname = gitlabBasePathURL.hostname;
        oauthAuthorizeURLWithChallenge.pathname = `${
          gitlabBasePathURL.pathname === '/' ? '' : gitlabBasePathURL.pathname
        }${oauthAuthorizeURLWithChallenge.pathname}`;
      }

      return oauthAuthorizeURLWithChallenge.toString();
    },
    async startOAuthFlow() {
      try {
        this.loading = true;
        const oauthAuthorizeURL = await this.getOauthAuthorizeURL();

        // eslint-disable-next-line no-restricted-properties
        window.open(oauthAuthorizeURL, I18N_DEFAULT_SIGN_IN_BUTTON_TEXT, OAUTH_WINDOW_OPTIONS);
      } catch (e) {
        if (e.message) {
          this.setAlert({
            message: e.message,
            variant: 'danger',
          });
        } else {
          this.setAlert({
            linkUrl: OAUTH_SELF_MANAGED_DOC_LINK,
            title: I18N_OAUTH_FAILED_TITLE,
            message: this.isGitlabCom ? '' : I18N_OAUTH_FAILED_MESSAGE,
            variant: 'danger',
          });
        }
        this.loading = false;
      }
    },
    async handleWindowMessage(event) {
      // Make sure this ia a message from the OAuth flow in pages/jira_connect/oauth_callbacks/index.js
      if (event.data?.type !== OAUTH_CALLBACK_MESSAGE_TYPE) {
        return;
      }

      if (window.origin !== event.origin) {
        this.loading = false;
        return;
      }

      // Verify that OAuth state isn't altered.
      const state = event.data?.state;
      if (state !== this.oauthMetadata.state) {
        this.loading = false;
        this.handleError();
        return;
      }

      // Request access token and load the authenticated user.
      const code = event.data?.code;
      try {
        const accessToken = await this.getOAuthToken(code);
        await this.loadCurrentUser(accessToken);

        this.setAccessToken(accessToken);
        this.$emit('sign-in');
      } catch (e) {
        this.handleError();
      } finally {
        this.loading = false;
      }
    },
    handleError() {
      this.$emit('error');
    },
    async getOAuthToken(code) {
      const { oauth_token_payload: oauthTokenPayload, oauth_token_path: oauthTokenPath } =
        this.oauthMetadata;
      const { data } = await fetchOAuthToken(oauthTokenPath, {
        ...oauthTokenPayload,
        code,
        code_verifier: this.codeVerifier,
        client_id: this.clientId,
      });

      return data.access_token;
    },
  },
};
</script>

<template>
  <gl-button
    v-bind="$attrs"
    variant="confirm"
    :loading="loading"
    :disabled="!canUseCrypto"
    @click="startOAuthFlow"
  >
    <slot>
      {{ buttonText }}
    </slot>
  </gl-button>
</template>
