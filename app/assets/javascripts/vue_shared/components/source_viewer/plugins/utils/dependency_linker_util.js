import { escape } from 'lodash';
import { setAttributes } from '~/lib/utils/dom_utils';

export const createLink = (href, innerText) => {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  const rel = 'nofollow noreferrer noopener';
  const link = document.createElement('a');

  setAttributes(link, { href: escape(href), rel });
  link.innerText = escape(innerText);

  return link.outerHTML;
};

export const generateHLJSOpenTag = (type) => `<span class="hljs-${escape(type)}">&quot;`;
