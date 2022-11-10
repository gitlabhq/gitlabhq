import { escape } from 'lodash';

export const createLink = (href, innerText) =>
  `<a href="${escape(href)}" target="_blank" rel="nofollow noreferrer noopener">${escape(
    innerText,
  )}</a>`;

export const generateHLJSOpenTag = (type, delimiter = '&quot;') =>
  `<span class="hljs-${escape(type)}">${delimiter}`;
