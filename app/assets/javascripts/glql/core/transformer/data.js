import { omit } from 'lodash';

const DATA_SOURCES = ['epics', 'issues', 'mergeRequests', 'workItems'];

const transformWorkItems = (workItems) => {
  for (const workItem of workItems.nodes || []) {
    for (const widget of workItem.widgets || []) {
      Object.assign(workItem, omit(widget, ['type', '__typename']));
    }
    delete workItem.widgets;
  }

  return workItems;
};

const transformForDataSource = (data) => {
  const scope = data.project || data.group;

  let source;
  let transformed;

  for (source of DATA_SOURCES) {
    if (source in scope) {
      transformed = scope[source];
      break;
    }
  }

  if (source === 'workItems') {
    transformed = transformWorkItems(structuredClone(transformed));
  }

  return { source, transformed };
};

const transformField = (data, field) => {
  if (field.transform)
    return {
      ...data,
      nodes: data.nodes.map((node) => field.transform(node)),
    };
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
