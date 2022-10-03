import { escape } from 'lodash';

export const createLink = (href, innerText) =>
  `<a href="${escape(href)}" rel="nofollow noreferrer noopener">${escape(innerText)}</a>`;

export const generateHLJSOpenTag = (type, delimiter = '&quot;') =>
  `<span class="hljs-${escape(type)}">${delimiter}`;
