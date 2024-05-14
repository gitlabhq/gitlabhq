import { mockGetProjectStorageStatisticsGraphQLResponse } from 'jest/usage_quotas/storage/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';
import getProjectStorageStatisticsQuery from 'ee_else_ce/usage_quotas/storage/project/queries/project_storage.query.graphql';
import ProjectStorageApp from './project_storage_app.vue';

const meta = {
  title: 'usage_quotas/storage/project/project_storage_app',
  component: ProjectStorageApp,
};

export default meta;

const createTemplate = (config = {}) => {
  let { provide, apolloProvider } = config;

  if (provide == null) {
    provide = {};
  }

  if (apolloProvider == null) {
    const requestHandlers = [
      [
        getProjectStorageStatisticsQuery,
        () => Promise.resolve(mockGetProjectStorageStatisticsGraphQLResponse),
      ],
    ];
    apolloProvider = createMockApollo(requestHandlers);
  }

  return (args, { argTypes }) => ({
    components: { ProjectStorageApp },
    apolloProvider,
    provide: {
      projectPath: '/namespace/project',
      ...provide,
    },
    props: Object.keys(argTypes),
    template: '<project-storage-app />',
  });
};

export const Default = {
  render: createTemplate(),
};

export const Loading = {
  render(...args) {
    const requestHandlers = [[getProjectStorageStatisticsQuery, () => new Promise(() => {})]];
    const apolloProvider = createMockApollo(requestHandlers);
    return createTemplate({
      apolloProvider,
    })(...args);
  },
};

export const LoadingError = {
  render(...args) {
    const requestHandlers = [[getProjectStorageStatisticsQuery, () => Promise.reject()]];
    const apolloProvider = createMockApollo(requestHandlers);
    return createTemplate({
      apolloProvider,
    })(...args);
  },
};
