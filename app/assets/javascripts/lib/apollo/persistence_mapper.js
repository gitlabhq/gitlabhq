// this file is based on https://github.com/apollographql/apollo-cache-persist/blob/master/examples/react-native/src/utils/persistence/persistenceMapper.ts
// with some heavy refactororing

/* eslint-disable no-underscore-dangle */
/* eslint-disable no-param-reassign */
/* eslint-disable dot-notation */
export const persistenceMapper = async (data) => {
  const parsed = JSON.parse(data);

  const mapped = {};
  const persistEntities = [];
  const rootQuery = parsed['ROOT_QUERY'];

  // cache entities that have `__persist: true`
  Object.keys(parsed).forEach((key) => {
    if (parsed[key]['__persist']) {
      persistEntities.push(key);
    }
  });

  // cache root queries that have `@persist` directive
  mapped['ROOT_QUERY'] = Object.keys(rootQuery).reduce(
    (obj, key) => {
      if (key === '__typename') return obj;

      if (/@persist$/.test(key)) {
        obj[key] = rootQuery[key];

        if (Array.isArray(rootQuery[key])) {
          const entities = rootQuery[key].map((item) => item.__ref);
          persistEntities.push(...entities);
        } else {
          const entity = rootQuery[key].__ref;
          if (entity) {
            persistEntities.push(entity);
          }
        }
      }

      return obj;
    },
    { __typename: 'Query' },
  );

  persistEntities.reduce((obj, key) => {
    const parsedEntity = parsed[key];

    // check for root queries and only cache root query properties that have `__persist: true`
    // we need this to prevent overcaching when we fetch the same entity (e.g. project) more than once
    // with different set of fields

    if (Object.values(rootQuery).some((value) => value?.__ref === key)) {
      const mappedEntity = {};
      Object.entries(parsedEntity).forEach(([parsedKey, parsedValue]) => {
        if (!parsedValue || typeof parsedValue !== 'object' || parsedValue['__persist']) {
          mappedEntity[parsedKey] = parsedValue;
        }
      });
      obj[key] = mappedEntity;
    } else {
      obj[key] = parsed[key];
    }

    return obj;
  }, mapped);

  return JSON.stringify(mapped);
};
