import { glql } from '@gitlab/query-language-rust';
import { glqlAggregationEnabled } from '../utils/feature_flags';

export const transform = async (data, config) => {
  const result = await glql.transform(data, {
    fields: config.fields,
    aggregate: glqlAggregationEnabled() ? config.aggregate : undefined,
  });

  if (!result.success) throw new Error(result.error);

  // eslint-disable-next-line no-param-reassign
  config.source = result.source || 'issues';
  // eslint-disable-next-line no-param-reassign
  config.fields = result.fields;
  return result.data;
};
