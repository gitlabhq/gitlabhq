import mockGetProjectStorageStatisticsGraphQLResponse from 'test_fixtures/graphql/usage_quotas/storage/project/project_storage.query.graphql.json';
import mockGetNamespaceStorageGraphQLResponse from 'test_fixtures/graphql/usage_quotas/storage/namespace/namespace_storage.query.graphql.json';
import mockGetProjectListStorageGraphQLResponse from 'test_fixtures/graphql/usage_quotas/storage/namespace/project_list_storage.query.graphql.json';
import { storageTypeHelpPaths } from '~/usage_quotas/storage/constants';

export { mockGetProjectStorageStatisticsGraphQLResponse };
export { mockGetNamespaceStorageGraphQLResponse };
export { mockGetProjectListStorageGraphQLResponse };

export const { namespace } = mockGetNamespaceStorageGraphQLResponse.data;
export const projectList = mockGetProjectListStorageGraphQLResponse.data.namespace.projects.nodes;

export const mockEmptyResponse = { data: { project: null } };

export const defaultProjectProvideValues = {
  projectPath: '/project-path',
};

export const defaultNamespaceProvideValues = {
  namespaceId: 0,
  namespacePath: 'GitLab',
  userNamespace: false,
  defaultPerPage: 20,
  customSortKey: null,
  helpLinks: storageTypeHelpPaths,
  // only used in EE
  purchaseStorageUrl: undefined,
  buyAddonTargetAttr: undefined,
  namespacePlanName: undefined,
  isInNamespaceLimitsPreEnforcement: undefined,
  perProjectStorageLimit: undefined,
  namespaceStorageLimit: undefined,
  totalRepositorySizeExcess: undefined,
  isUsingProjectEnforcementWithLimits: undefined,
  isUsingProjectEnforcementWithNoLimits: undefined,
  aboveSizeLimit: undefined,
  subjectToHighLimit: undefined,
  isUsingNamespaceEnforcement: undefined,
};

export const storageTypes = [
  { key: 'storage' },
  { key: 'repository' },
  { key: 'snippets' },
  { key: 'buildArtifacts' },
  { key: 'containerRegistry' },
  { key: 'lfsObjects' },
  { key: 'packages' },
  { key: 'wiki' },
];
