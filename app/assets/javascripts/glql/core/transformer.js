import { glql } from '@gitlab/query-language-rust';
import { glqlAggregationEnabled } from '../utils/feature_flags';

export const transform = async (data = { project: { issues: { nodes: [] } } }, config) => {
  const result = await glql.transform(data, {
    fields: config.fields,
    aggregate: glqlAggregationEnabled() ? config.aggregate : undefined,
  });

  if (!result.success) throw new Error(result.error);

  return { data: result.data, fields: result.fields };
};
