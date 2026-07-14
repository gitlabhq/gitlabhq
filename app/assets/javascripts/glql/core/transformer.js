import { glql } from '@gitlab/query-language-rust';

export const transform = async (data, { fields, mode, source }) => {
  const result = await glql.transform(data, {
    fields,
    mode,
    source,
  });

  if (!result.success) throw new Error(result.error);

  return result.data;
};
