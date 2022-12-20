import DOMPurify from 'dompurify';
import { getNormalizedURL, getBaseURL, relativePathToAbsolute } from '~/lib/utils/url_utility';

const { sanitize: dompurifySanitize, addHook, isValidAttribute } = DOMPurify;

export const defaultConfig = {
  // Safely allow SVG <use> tags
  ADD_TAGS: ['use', 'gl-emoji', 'copy-code'],
  // Prevent possible XSS attacks with data-* attributes used by @rails/ujs
  // See https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1421
  FORBID_ATTR: [
    'data-remote',
    'data-url',
    'data-type',
    'data-method',
    'data-disable-with',
    'data-disabled',
    'data-disable',
    'data-turbo',
  ],
  FORBID_TAGS: ['style', 'mstyle', 'form'],
  ALLOW_UNKNOWN_PROTOCOLS: true,
};

// Only icons urls from `gon` are allowed
const getAllowedIconUrls = (gon = window.gon) =>
  [gon.sprite_file_icons, gon.sprite_icons]
    .filter(Boolean)
    .map((path) => relativePathToAbsolute(path, getBaseURL()));

const isUrlAllowed = (url) =>
  getAllowedIconUrls().some((allowedUrl) => getNormalizedURL(url).startsWith(allowedUrl));

const isHrefSafe = (url) => url.match(/^#/) || isUrlAllowed(url);

const removeUnsafeHref = (node, attr) => {
  if (!node.hasAttribute(attr)) {
    return;
  }

  if (!isHrefSafe(node.getAttribute(attr))) {
    node.removeAttribute(attr);
  }
};

/**
 * Appends 'noopener' & 'noreferrer' to rel
 * attr values to prevent reverse tabnabbing.
 *
 * @param {String} rel
 * @returns {String}
 */
const appendSecureRelValue = (rel) => {
  const attributes = new Set(rel ? rel.toLowerCase().split(' ') : []);

  attributes.add('noopener');
  attributes.add('noreferrer');

  return Array.from(attributes).join(' ');
};

/**
 * Sanitize icons' <use> tag attributes, to safely include
 * svgs such as in:
 *
 * <svg viewBox="0 0 100 100">
 *   <use href="/assets/icons-xxx.svg#icon_name"></use>
 * </svg>
 *
 * It validates both href & xlink:href attributes.
 * Note that `xlink:href` is deprecated, but still in use
 * https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/xlink:href
 *
 * @param {Object} node - Node to sanitize
 */
const sanitizeSvgIcon = (node) => {
  removeUnsafeHref(node, 'href');
  removeUnsafeHref(node, 'xlink:href');
};

addHook('afterSanitizeAttributes', (node) => {
  if (node.tagName.toLowerCase() === 'use') {
    sanitizeSvgIcon(node);
  }
});

const TEMPORARY_ATTRIBUTE = 'data-temp-href-target';

addHook('beforeSanitizeAttributes', (node) => {
  if (node.tagName === 'A' && node.hasAttribute('target')) {
    node.setAttribute(TEMPORARY_ATTRIBUTE, node.getAttribute('target'));
  }
});

addHook('afterSanitizeAttributes', (node) => {
  if (node.tagName === 'A' && node.hasAttribute(TEMPORARY_ATTRIBUTE)) {
    node.setAttribute('target', node.getAttribute(TEMPORARY_ATTRIBUTE));
    node.removeAttribute(TEMPORARY_ATTRIBUTE);
    if (node.getAttribute('target') === '_blank') {
      const rel = node.getAttribute('rel');
      node.setAttribute('rel', appendSecureRelValue(rel));
    }
  }
});

export const sanitize = (val, config) => dompurifySanitize(val, { ...defaultConfig, ...config });

export { isValidAttribute };
