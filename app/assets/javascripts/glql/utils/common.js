import { upperFirst, lowerCase } from 'lodash';

export const extractGroupOrProject = (url = window.location.href) => {
  let fullPath = url
    .replace(window.location.origin, '')
    .split('/-/')[0]
    .replace(new RegExp(`^${gon.relative_url_root}/`), '/');

  const isGroup = fullPath.startsWith('/groups');
  fullPath = fullPath.replace(/^\/groups\//, '').replace(/^\//g, '');
  if (isGroup) return { group: fullPath };
  if (fullPath) return { project: fullPath };
  return {};
};

export const toSentenceCase = (str) => {
  if (str === 'id' || str === 'iid') return str.toUpperCase();
  return upperFirst(lowerCase(str));
};
