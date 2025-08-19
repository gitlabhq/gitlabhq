import { glql } from '@gitlab/query-language-rust';
import { glqlAggregationEnabled } from '../utils/feature_flags';

export const transform = async (data, config) => {
  const result = await glql.transform(data, {
    fields: config.fields,
    aggregate: glqlAggregationEnabled() ? config.aggregate : undefined,
  });

  if (!result.success) throw new Error(result.error);

  return result.data;
};
