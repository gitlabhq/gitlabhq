import mockGetProjectStorageStatisticsGraphQLResponse from 'test_fixtures/graphql/usage_quotas/storage/project_storage.query.graphql.json';

export { mockGetProjectStorageStatisticsGraphQLResponse };
export const mockEmptyResponse = { data: { project: null } };

export const defaultProjectProvideValues = {
  projectPath: '/project-path',
};
