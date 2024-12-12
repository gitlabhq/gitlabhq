import jsYaml from 'js-yaml';
import { parseYAMLConfig } from './config';
import { parseQuery } from './query';

const DEFAULT_DISPLAY_FIELDS = ['title'];

export const parseQueryTextWithFrontmatter = (text) => {
  const frontmatter = text.match(/---\n([\s\S]*?)\n---/);
  const remaining = text.replace(frontmatter ? frontmatter[0] : '', '');
  return {
    frontmatter: frontmatter ? frontmatter[1].trim() : '',
    query: remaining.trim(),
  };
};

const isValidYAML = (text) => typeof jsYaml.safeLoad(text) === 'object';

export const parse = async (glqlQuery, target = 'graphql') => {
  let { frontmatter: config, query } = parseQueryTextWithFrontmatter(glqlQuery);
  if (!config && isValidYAML(glqlQuery)) {
    // if frontmatter isn't present, query is a part of the config
    ({ query, ...config } = parseYAMLConfig(glqlQuery, { fields: DEFAULT_DISPLAY_FIELDS }));
  } else {
    config = parseYAMLConfig(config, { fields: DEFAULT_DISPLAY_FIELDS });
  }

  const limit = parseInt(config.limit, 10) || undefined;

  return { query: await parseQuery(query, { ...config, target, limit }), config };
};
