export const mockModels = [
  {
    name: 'model_1',
    version: '1.0',
    path: 'path/to/model_1',
    versionCount: 3,
  },
  {
    name: 'model_2',
    version: '1.1',
    path: 'path/to/model_2',
    versionCount: 1,
  },
];

export const modelWithoutVersion = {
  name: 'model_without_version',
  path: 'path/to/model_without_version',
  versionCount: 0,
};

export const startCursor = 'eyJpZCI6IjE2In0';

export const defaultPageInfo = Object.freeze({
  startCursor,
  endCursor: 'eyJpZCI6IjIifQ',
  hasNextPage: true,
  hasPreviousPage: true,
});
