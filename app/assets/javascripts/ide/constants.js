export const DEFAULT_BRANCH = 'main';

export const GITLAB_WEB_IDE_FEEDBACK_ISSUE = 'https://gitlab.com/gitlab-org/gitlab/-/issues/377367';

export const IDE_ELEMENT_ID = 'ide';

// note: This path comes from `config/routes.rb`
export const IDE_PATH = '/-/ide';
export const WEB_IDE_OAUTH_CALLBACK_URL_PATH = '/-/ide/oauth_redirect';

/**
 * LEGACY WEB IDE CONSTANTS USED BY OTHER FRONTEND FEATURES. DO NOT CONTINUE USING.
 */
export const diffModes = {
  replaced: 'replaced',
  new: 'new',
  deleted: 'deleted',
  renamed: 'renamed',
  mode_changed: 'mode_changed',
};

export const diffViewerModes = Object.freeze({
  not_diffable: 'not_diffable',
  no_preview: 'no_preview',
  added: 'added',
  deleted: 'deleted',
  renamed: 'renamed',
  mode_changed: 'mode_changed',
  text: 'text',
  image: 'image',
});

export const diffViewerErrors = Object.freeze({
  too_large: 'too_large',
  stored_externally: 'server_side_but_stored_externally',
});

export const commitItemIconMap = {
  addition: {
    icon: 'file-addition',
    class: 'file-addition ide-file-addition',
  },
  modified: {
    icon: 'file-modified',
    class: 'file-modified ide-file-modified',
  },
  deleted: {
    icon: 'file-deletion',
    class: 'file-deletion ide-file-deletion',
  },
};
