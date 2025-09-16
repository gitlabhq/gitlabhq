import { glql } from '@gitlab/query-language-rust';
import { glqlAggregationEnabled } from '../utils/feature_flags';

export const transform = async (data, { groupBy, aggregate, ...config }) => {
  const result = await glql.transform(data, {
    fields: config.fields,
    ...(glqlAggregationEnabled() ? { groupBy, aggregate } : {}),
  });

  if (!result.success) throw new Error(result.error);

  return result.data;
};
