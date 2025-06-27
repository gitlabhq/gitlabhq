import jsYaml from 'js-yaml';
import { glql } from '@gitlab/query-language-rust';
import { extractGroupOrProject } from '../utils/common';
import { glqlFeatureFlags } from '../utils/feature_flags';

const DEFAULT_DISPLAY_FIELDS = 'title';
const REQUIRED_QUERY_FIELDS = 'id, iid, title, webUrl, reference, state';

const isValidYAML = (text) => typeof jsYaml.safeLoad(text) === 'object';

export const parseYAMLConfig = (frontmatter) => {
  const config = jsYaml.safeLoad(frontmatter) || {};

  config.display = config.display || 'list';
  config.fields = config.fields || DEFAULT_DISPLAY_FIELDS;

  return config;
};

export const parseQueryTextWithFrontmatter = (text) => {
  const frontmatter = text.match(/---\n([\s\S]*?)\n---/);
  const remaining = text.replace(frontmatter ? frontmatter[0] : '', '');
  return {
    frontmatter: frontmatter ? frontmatter[1].trim() : '',
    query: remaining.trim(),
  };
};

export const parseQuery = async (query, config) => {
  const { output, success, variables } = await glql.compile(query, {
    ...config,
    ...extractGroupOrProject(),
    username: gon.current_username,
    fields: `${REQUIRED_QUERY_FIELDS}, ${config.fields}`,
    featureFlags: glqlFeatureFlags(),
  });

  if (!success) throw new Error(output);

  return { query: output, variables };
};

export const parse = async (glqlQuery) => {
  let { frontmatter: config, query } = parseQueryTextWithFrontmatter(glqlQuery);
  if (!config && isValidYAML(glqlQuery)) {
    // if frontmatter isn't present, query is a part of the config
    ({ query, ...config } = parseYAMLConfig(glqlQuery));
  } else {
    config = parseYAMLConfig(config);
  }

  const limit = parseInt(config.limit, 10) || undefined;
  const parsed = await parseQuery(query, { ...config, limit });

  return { query: parsed.query, variables: parsed.variables, config };
};
