import jsYaml from 'js-yaml';
import { uniq } from 'lodash';

export const extractGroupOrProject = () => {
  const url = window.location.href;
  let fullPath = url
    .replace(window.location.origin, '')
    .split('/-/')[0]
    .replace(new RegExp(`^${gon.relative_url_root}/`), '/');

  const isGroup = fullPath.startsWith('/groups');
  fullPath = fullPath.replace(/^\/groups\//, '').replace(/^\//g, '');
  return {
    group: isGroup ? fullPath : undefined,
    project: !isGroup ? fullPath : undefined,
  };
};

export const parseQueryText = (text) => {
  const frontmatter = text.match(/---\n([\s\S]*?)\n---/);
  const remaining = text.replace(frontmatter ? frontmatter[0] : '', '');
  return {
    frontmatter: frontmatter ? frontmatter[1].trim() : '',
    query: remaining.trim(),
  };
};

export const parseFrontmatter = (frontmatter, defaults = {}) => {
  const config = jsYaml.safeLoad(frontmatter) || {};
  config.fields = uniq(config.fields?.split(',').map((f) => f.trim()) || defaults?.fields);
  config.display = config.display || 'list';
  return config;
};
