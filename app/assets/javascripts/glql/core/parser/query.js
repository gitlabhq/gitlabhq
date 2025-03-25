import { uniq, once } from 'lodash';
import { GitLabQueryLanguage as QueryParser } from '@gitlab/query-language-rust';
import { extractGroupOrProject } from '../../utils/common';
import { glqlWorkItemsFeatureFlagEnabled } from '../../utils/feature_flags';

const REQUIRED_QUERY_FIELDS = ['id', 'iid', 'title', 'webUrl', 'reference', 'state'];

const initParser = once(async () => {
  const parser = QueryParser();
  const { group, project } = extractGroupOrProject();

  parser.group = group || '';
  parser.project = project || '';
  parser.username = gon.current_username || '';
  await parser.initialize();

  return parser;
});

export const parseQuery = async (query, config) => {
  const parser = await initParser();
  parser.fields = uniq([...REQUIRED_QUERY_FIELDS, ...config.fields.map(({ name }) => name)]);

  const target = glqlWorkItemsFeatureFlagEnabled() ? 'work_items_graphql' : 'graphql';
  const { output } = parser.compile(target, query, config);

  if (output.toLowerCase().startsWith('error')) throw new Error(output.replace(/^error: /i, ''));

  return output;
};
