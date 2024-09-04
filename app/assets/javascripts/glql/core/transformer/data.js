import { __, sprintf } from '~/locale';

const dataSourceTransformers = {
  issues: (data) => (data.project || data.group).issues,
};

const transformForDataSource = (data, source = 'issues') => {
  const dataSource = dataSourceTransformers[source];
  if (!dataSource) throw new Error(sprintf(__('Unknown data source: %{source}'), { source }));
  return dataSource(data);
};

const transformField = (data, field) => {
  if (field.transform) return field.transform(data);
  return data;
};

const transformFields = (data, fields) => {
  return fields.reduce((acc, field) => transformField(acc, field), data);
};

export const transform = (data, config) => {
  let transformed = data;
  transformed = transformForDataSource(transformed, config.source);
  transformed = transformFields(transformed, config.fields);

  return transformed;
};
