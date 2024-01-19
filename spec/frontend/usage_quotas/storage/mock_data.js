import mockGetProjectStorageStatisticsGraphQLResponse from 'test_fixtures/graphql/usage_quotas/storage/project_storage.query.graphql.json';
import mockGetNamespaceStorageGraphQLResponse from 'test_fixtures/graphql/usage_quotas/storage/namespace_storage.query.graphql.json';
import mockGetProjectListStorageGraphQLResponse from 'test_fixtures/graphql/usage_quotas/storage/project_list_storage.query.graphql.json';

export { mockGetProjectStorageStatisticsGraphQLResponse };
export { mockGetNamespaceStorageGraphQLResponse };
export { mockGetProjectListStorageGraphQLResponse };

export const mockEmptyResponse = { data: { project: null } };

export const defaultProjectProvideValues = {
  projectPath: '/project-path',
};

export const defaultNamespaceProvideValues = {
  userNamespace: false,
  namespaceId: '42',
};
