const dataSourceTransformers = {
  issues: (data) => (data.project || data.group).issues,
  mergeRequests: (data) => (data.project || data.group).mergeRequests,
};

const transformForDataSource = (data) => {
  for (const [source, transformer] of Object.entries(dataSourceTransformers)) {
    const transformed = transformer(data);
    if (transformed) return { source, transformed };
  }
  return undefined;
};

const transformField = (data, field) => {
  if (field.transform) return field.transform(data);
  return data;
};

const transformFields = (data, fields) => {
  return fields.reduce((acc, field) => transformField(acc, field), data);
};

export const transform = (data, config) => {
  let source = config.source || 'issues';
  let transformed = data;

  ({ transformed, source } = transformForDataSource(transformed) || {});
  transformed = transformFields(transformed, config.fields);

  // eslint-disable-next-line no-param-reassign
  if (source) config.source = source;
  return transformed;
};
