// component selectors
const CHANGE_MR_ID_BUTTON = 'gitlab-change-mr';
const COLLAPSE_BUTTON = 'gitlab-collapse';
const COMMENT_BOX = 'gitlab-comment';
const COMMENT_BUTTON = 'gitlab-comment-button';
const FORM = 'gitlab-form';
const FORM_CONTAINER = 'gitlab-form-wrapper';
const LOGIN = 'gitlab-login-button';
const LOGOUT = 'gitlab-logout-button';
const MR_ID = 'gitlab-submit-mr';
const MR_ID_BUTTON = 'gitlab-submit-mr-button';
const NOTE = 'gitlab-validation-note';
const NOTE_CONTAINER = 'gitlab-note-wrapper';
const REMEMBER_ITEM = 'gitlab-remember-item';
const REVIEW_CONTAINER = 'gitlab-review-container';
const TOKEN_BOX = 'gitlab-token';

// Storage keys
const STORAGE_PREFIX = '--gitlab'; // Using `--` to make the prefix more unique
const STORAGE_MR_ID = `${STORAGE_PREFIX}-merge-request-id`;
const STORAGE_TOKEN = `${STORAGE_PREFIX}-token`;
const STORAGE_COMMENT = `${STORAGE_PREFIX}-comment`;

// colors — these are applied programmatically
// rest of styles belong in ./styles
const BLACK = 'rgba(46, 46, 46, 1)';
const CLEAR = 'rgba(255, 255, 255, 0)';
const MUTED = 'rgba(223, 223, 223, 0.5)';
const RED = 'rgba(219, 59, 33, 1)';
const WHITE = 'rgba(250, 250, 250, 1)';

export {
  CHANGE_MR_ID_BUTTON,
  COLLAPSE_BUTTON,
  COMMENT_BOX,
  COMMENT_BUTTON,
  FORM,
  FORM_CONTAINER,
  LOGIN,
  LOGOUT,
  MR_ID,
  MR_ID_BUTTON,
  NOTE,
  NOTE_CONTAINER,
  REMEMBER_ITEM,
  REVIEW_CONTAINER,
  TOKEN_BOX,
  STORAGE_MR_ID,
  STORAGE_TOKEN,
  STORAGE_COMMENT,
  BLACK,
  CLEAR,
  MUTED,
  RED,
  WHITE,
};
