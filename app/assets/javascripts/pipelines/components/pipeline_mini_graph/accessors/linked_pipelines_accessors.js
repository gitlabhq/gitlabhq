import { get } from 'lodash';

export const accessors = {
  rest: {
    detailedStatus: ['details', 'status'],
  },
  graphql: {
    detailedStatus: 'detailedStatus',
  },
};

export const accessValue = (pipeline, dataMethod, path) => {
  return get(pipeline, accessors[dataMethod][path]);
};
