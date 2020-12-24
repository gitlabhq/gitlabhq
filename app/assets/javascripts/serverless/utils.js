// Validate that the object coming in has valid query details and results
export const validateGraphData = (data) =>
  data.queries &&
  Array.isArray(data.queries) &&
  data.queries.filter((query) => {
    if (Array.isArray(query.result)) {
      return query.result.filter((res) => Array.isArray(res.values)).length === query.result.length;
    }

    return false;
  }).length === data.queries.length;

export const translate = (functions) =>
  functions.reduce(
    (acc, func) =>
      Object.assign(acc, {
        [func.environment_scope]: (acc[func.environment_scope] || []).concat([func]),
      }),
    {},
  );
