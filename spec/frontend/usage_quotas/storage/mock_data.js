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
export const mockProjectStorageStatisticsNoStorageResponse = {
  data: {
    project: {
      ...mockGetProjectStorageStatisticsGraphQLResponse.data.project,
      statistics: {
        ...mockGetProjectStorageStatisticsGraphQLResponse.data.project.statistics,
        storageSize: 0,
      },
    },
  },
};

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

export const MOCK_REPOSITORY = {
  project: {
    id: 'gid://gitlab/Project/1',
  },
};

export const MOCK_REPOSITORY_HEALTH_DETAILS = {
  updatedAt: '2026-01-01T00:00:00.000Z',
  lastFullRepack: {
    seconds: 1640995200, // 2022-01-01 00:00:00 UTC
  },
  size: 5000,
  objects: {
    size: 3000,
    recentSize: 1500,
    staleSize: 1500,
    packfileCount: 5,
    cruftCount: 2,
    looseObjectsCount: 100,
  },
  references: {
    packedSize: 2000,
    looseCount: 42,
  },
  commitGraph: {
    hasBloomFilters: true,
    hasGenerationData: true,
    hasGenerationDataOverflow: false,
    commitGraphChainLength: 5,
  },
  bitmap: {
    hasHashCache: true,
    hasLookupTable: false,
  },
  multiPackIndexBitmap: {
    hasHashCache: false,
    hasLookupTable: true,
  },
  multiPackIndex: {
    packfileCount: 12,
  },
};
