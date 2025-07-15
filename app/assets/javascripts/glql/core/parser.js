import jsYaml from 'js-yaml';
import { glql } from '@gitlab/query-language-rust';
import { DEFAULT_DISPLAY_FIELDS, DEFAULT_DISPLAY_TYPE, REQUIRED_QUERY_FIELDS } from '../constants';
import { extractGroupOrProject } from '../utils/common';
import { glqlFeatureFlags } from '../utils/feature_flags';

const isValidYAML = (text) => typeof jsYaml.safeLoad(text) === 'object';

export const parseYAMLConfig = (frontmatter) => {
  const config = jsYaml.safeLoad(frontmatter) || {};

  config.display = config.display || DEFAULT_DISPLAY_TYPE;
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

  return { query: output, variables, config };
};

export const parseYAML = (yaml) => {
  let { frontmatter: config, query } = parseQueryTextWithFrontmatter(yaml);
  if (!config && isValidYAML(yaml)) {
    // if frontmatter isn't present, query is a part of the config
    ({ query, ...config } = parseYAMLConfig(yaml));
  } else {
    config = parseYAMLConfig(config);
  }

  return { query, config };
};

export const parse = (yaml) => {
  const { query, config } = parseYAML(yaml);
  return parseQuery(query, config);
};
