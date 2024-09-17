import { parseConfig } from './config';
import { parseQuery } from './query';

const DEFAULT_DISPLAY_FIELDS = ['title'];

export const parseQueryText = (text) => {
  const frontmatter = text.match(/---\n([\s\S]*?)\n---/);
  const remaining = text.replace(frontmatter ? frontmatter[0] : '', '');
  return {
    frontmatter: frontmatter ? frontmatter[1].trim() : '',
    query: remaining.trim(),
  };
};

export const parse = async (glqlQuery, target = 'graphql') => {
  const { frontmatter, query } = parseQueryText(glqlQuery);
  const config = parseConfig(frontmatter, { fields: DEFAULT_DISPLAY_FIELDS });
  const limit = parseInt(config.limit, 10) || undefined;

  return { query: await parseQuery(query, { ...config, target, limit }), config };
};
