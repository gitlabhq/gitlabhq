import { s__ } from '~/locale';

export const DEFAULT_GROUPS_PER_PAGE = 10;
export const ALERT_LOCALSTORAGE_KEY = 'gitlab_alert';
export const MINIMUM_SEARCH_TERM_LENGTH = 3;

export const ADD_NAMESPACE_MODAL_ID = 'add-namespace-modal';

export const I18N_DEFAULT_SIGN_IN_BUTTON_TEXT = s__('Integrations|Sign in to GitLab');
export const I18N_DEFAULT_SIGN_IN_ERROR_MESSAGE = s__('Integrations|Failed to sign in to GitLab.');

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

export const PKCE_CODE_CHALLENGE_DIGEST_ALGORITHM = {
  long: 'SHA-256',
  short: 'S256',
};
