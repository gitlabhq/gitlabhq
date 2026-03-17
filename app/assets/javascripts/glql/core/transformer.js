import { glql } from '@gitlab/query-language-rust';

export const transform = async (data, config) => {
  const result = await glql.transform(data, {
    fields: config.fields,
  });

  if (!result.success) throw new Error(result.error);

  return result.data;
};
