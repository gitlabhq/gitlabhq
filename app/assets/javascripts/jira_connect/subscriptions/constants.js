import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const DEFAULT_GROUPS_PER_PAGE = 10;
export const ALERT_LOCALSTORAGE_KEY = 'gitlab_alert';
export const BASE_URL_LOCALSTORAGE_KEY = 'gitlab_base_url';
export const MINIMUM_SEARCH_TERM_LENGTH = 3;

export const ADD_NAMESPACE_MODAL_ID = 'add-namespace-modal';

export const I18N_DEFAULT_SIGN_IN_BUTTON_TEXT = __('Sign in to GitLab');
export const I18N_CUSTOM_SIGN_IN_BUTTON_TEXT = s__('JiraConnect|Sign in to %{url}');
export const I18N_DEFAULT_SIGN_IN_ERROR_MESSAGE = s__('JiraConnect|Failed to sign in to GitLab.');
export const I18N_DEFAULT_SUBSCRIPTIONS_ERROR_MESSAGE = s__(
  'JiraConnect|Failed to load subscriptions.',
);
export const I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_TITLE = s__(
  'JiraConnect|Group successfully linked',
);
export const I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_MESSAGE = s__(
  'JiraConnect|You should now see GitLab.com activity inside your Jira Cloud issues. %{linkStart}Learn more%{linkEnd}',
);
export const I18N_ADD_SUBSCRIPTIONS_ERROR_MESSAGE = s__(
  'JiraConnect|Failed to link group. Please try again.',
);
export const I18N_UPDATE_INSTALLATION_ERROR_MESSAGE = s__(
  'JiraConnect|Failed to update the GitLab instance. See the %{linkStart}troubleshooting documentation%{linkEnd}.',
);
export const I18N_OAUTH_APPLICATION_ID_ERROR_MESSAGE = s__(
  'JiraConnect|Failed to load Jira Connect Application ID. Please try again.',
);
export const I18N_OAUTH_FAILED_TITLE = s__('JiraConnect|Failed to sign in to GitLab.');
export const I18N_OAUTH_FAILED_MESSAGE = s__(
  'JiraConnect|Ensure your instance URL is correct and your instance is configured correctly. %{linkStart}Learn more%{linkEnd}.',
);

export const INTEGRATIONS_DOC_LINK = helpPagePath('integration/jira/configure');
export const PREREQUISITES_DOC_LINK = helpPagePath('administration/settings/jira_cloud_app', {
  anchor: 'prerequisites',
});
export const OAUTH_SELF_MANAGED_DOC_LINK = helpPagePath('administration/settings/jira_cloud_app', {
  anchor: 'set-up-oauth-authentication',
});
export const SET_UP_INSTANCE_DOC_LINK = helpPagePath('administration/settings/jira_cloud_app', {
  anchor: 'set-up-your-instance',
});
export const JIRA_USER_REQUIREMENTS_DOC_LINK = helpPagePath(
  'administration/settings/jira_cloud_app',
  {
    anchor: 'jira-user-requirements',
  },
);
export const FAILED_TO_UPDATE_DOC_LINK = helpPagePath(
  'administration/settings/jira_cloud_app_troubleshooting',
  {
    anchor: 'error-failed-to-update-the-gitlab-instance',
  },
);

export const GITLAB_COM_BASE_PATH = 'https://gitlab.com';

const OAUTH_WINDOW_SIZE = 800;
export const OAUTH_WINDOW_OPTIONS = [
  'resizable=yes',
  'scrollbars=yes',
  'status=yes',
  `width=${OAUTH_WINDOW_SIZE}`,
  `height=${OAUTH_WINDOW_SIZE}`,
  `left=${window.screen.width / 2 - OAUTH_WINDOW_SIZE / 2}`,
  `top=${window.screen.height / 2 - OAUTH_WINDOW_SIZE / 2}`,
].join(',');

export const OAUTH_CALLBACK_MESSAGE_TYPE = 'jiraConnectOauthCallback';

export const PKCE_CODE_CHALLENGE_DIGEST_ALGORITHM = {
  long: 'SHA-256',
  short: 'S256',
};
