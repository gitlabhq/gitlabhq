import { escape } from 'lodash';

export const createLink = (href, innerText) =>
  `<a href="${escape(href)}" target="_blank" rel="nofollow noreferrer noopener">${escape(
    innerText,
  )}</a>`;

export const generateHLJSOpenTag = (type, delimiter = '&quot;') =>
  `<span class="hljs-${escape(type)}">${delimiter}`;

export const getObjectKeysByKeyName = (obj, keyName, acc) => {
  if (obj instanceof Array) {
    obj.map((subObj) => getObjectKeysByKeyName(subObj, keyName, acc));
  } else {
    for (const key in obj) {
      if (Object.prototype.hasOwnProperty.call(obj, key)) {
        if (key === keyName) {
          acc.push(...Object.keys(obj[key]));
        }
        if (obj[key] instanceof Object || obj[key] instanceof Array) {
          getObjectKeysByKeyName(obj[key], keyName, acc);
        }
      }
    }
  }
  return acc;
};
