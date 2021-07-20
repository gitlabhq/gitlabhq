import { sanitize as dompurifySanitize, addHook } from 'dompurify';
import { getBaseURL, relativePathToAbsolute } from '~/lib/utils/url_utility';

// Safely allow SVG <use> tags

const defaultConfig = {
  ADD_TAGS: ['use'],
};

const forbiddenDataAttrs = ['data-remote', 'data-url', 'data-type', 'data-method'];

// Only icons urls from `gon` are allowed
const getAllowedIconUrls = (gon = window.gon) =>
  [gon.sprite_file_icons, gon.sprite_icons].filter(Boolean);

const isUrlAllowed = (url) => getAllowedIconUrls().some((allowedUrl) => url.startsWith(allowedUrl));

const isHrefSafe = (url) =>
  isUrlAllowed(url) || isUrlAllowed(relativePathToAbsolute(url, getBaseURL()));

const removeUnsafeHref = (node, attr) => {
  if (!node.hasAttribute(attr)) {
    return;
  }

  if (!isHrefSafe(node.getAttribute(attr))) {
    node.removeAttribute(attr);
  }
};

/**
 * Sanitize icons' <use> tag attributes, to safely include
 * svgs such as in:
 *
 * <svg viewBox="0 0 100 100">
 *   <use href="/assets/icons-xxx.svg#icon_name"></use>
 * </svg>
 *
 * @param {Object} node - Node to sanitize
 */
const sanitizeSvgIcon = (node) => {
  removeUnsafeHref(node, 'href');

  // Note: `xlink:href` is deprecated, but still in use
  // https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/xlink:href
  removeUnsafeHref(node, 'xlink:href');
};

const sanitizeHTMLAttributes = (node) => {
  forbiddenDataAttrs.forEach((attr) => {
    if (node.hasAttribute(attr)) {
      node.removeAttribute(attr);
    }
  });
};

addHook('afterSanitizeAttributes', (node) => {
  if (node.tagName.toLowerCase() === 'use') {
    sanitizeSvgIcon(node);
  }
  sanitizeHTMLAttributes(node);
});

export const sanitize = (val, config = defaultConfig) => dompurifySanitize(val, config);
