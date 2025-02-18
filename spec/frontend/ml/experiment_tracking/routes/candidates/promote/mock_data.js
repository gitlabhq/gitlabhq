export const mockModelsQueryResult = {
  data: {
    project: {
      id: 111,
      mlModels: {
        count: 2,
        nodes: [
          {
            id: 'gid://gitlab/Ml::Model/1',
            name: 'model-1',
            createdAt: '2021-08-10T09:33:54Z',
            latestVersion: {
              id: 'gid://gitlab/Ml::ModelVersion/11',
              version: '1.0.43',
            },
          },
          {
            id: 'gid://gitlab/Ml::Model/2',
            name: 'model-2',
            createdAt: '2021-08-10T09:39:54Z',
            latestVersion: {
              id: 'gid://gitlab/Ml::ModelVersion/22',
              version: '1.2.3',
            },
          },
        ],
      },
    },
  },
};
export const mockModelNodes = mockModelsQueryResult.data.project.mlModels.nodes;
export const mockModelItems = mockModelNodes.map((model) => ({
  text: model.name,
  value: model.id,
  model,
}));
export const mockModelNames = mockModelNodes.map(({ name }) => name);
export const model42 = {
  id: 'gid://gitlab/Ml::Model/42',
  name: 'model-1',
  createdAt: '2021-08-10T09:42:54Z',
  latestVersion: {
    version: '1.0.42',
  },
};
