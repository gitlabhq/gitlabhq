import {
  defaultNamespaceProvideValues,
  mockGetNamespaceStorageGraphQLResponse,
  mockGetProjectListStorageGraphQLResponse,
} from 'jest/usage_quotas/storage/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';
import getNamespaceStorageQuery from 'ee_else_ce/usage_quotas/storage/namespace/queries/namespace_storage.query.graphql';
import getProjectListStorageQuery from 'ee_else_ce/usage_quotas/storage/namespace/queries/project_list_storage.query.graphql';
import NamespaceStorageApp from './namespace_storage_app.vue';

const meta = {
  title: 'usage_quotas/storage/namespace/namespace_storage_app',
  component: NamespaceStorageApp,
};

export default meta;

const createTemplate = (config = {}) => {
  let { provide, apolloProvider } = config;

  if (provide == null) {
    provide = {};
  }

  if (apolloProvider == null) {
    const requestHandlers = [
      [getNamespaceStorageQuery, () => Promise.resolve(mockGetNamespaceStorageGraphQLResponse)],
      [getProjectListStorageQuery, () => Promise.resolve(mockGetProjectListStorageGraphQLResponse)],
    ];
    apolloProvider = createMockApollo(requestHandlers);
  }

  return (args, { argTypes }) => ({
    components: { NamespaceStorageApp },
    apolloProvider,
    provide: {
      ...defaultNamespaceProvideValues,
      ...provide,
    },
    props: Object.keys(argTypes),
    template: '<namespace-storage-app />',
  });
};

export const Default = {
  render: createTemplate(),
};
