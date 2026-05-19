import { glql } from '@gitlab/query-language-rust';

export const transform = async (data, { fields, mode }) => {
  const result = await glql.transform(data, {
    fields,
    mode,
  });

  if (!result.success) throw new Error(result.error);

  return result.data;
};
