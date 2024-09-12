export const getModifierKey = (removeSuffix = false) => {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  const winKey = `Ctrl${removeSuffix ? '' : '+'}`;
  return window.gl?.client?.isMac ? '⌘' : winKey;
};

// The following default values are for frontend unit tests
const DEFAULT_FORUM_URL = 'https://forum.gitlab.com';
// eslint-disable-next-line no-restricted-syntax
const DEFAULT_DOCS_URL = 'https://docs.gitlab.com';
// eslint-disable-next-line no-restricted-syntax
const DEFAULT_PROMO_URL = 'https://about.gitlab.com';

const {
  forum_url: FORUM_URL = DEFAULT_FORUM_URL,
  docs_url: DOCS_URL = DEFAULT_DOCS_URL,
  promo_url: PROMO_URL = DEFAULT_PROMO_URL,
} = window.gon;

// eslint-disable-next-line no-restricted-syntax
export const DOCS_URL_IN_EE_DIR = `${DOCS_URL}/ee`;

export { FORUM_URL, DOCS_URL, PROMO_URL };

export const GL_DARK = 'gl-dark';
export const GL_LIGHT = 'gl-light';
export const GL_SYSTEM = 'gl-system';
