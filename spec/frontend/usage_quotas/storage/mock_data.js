import mockGetProjectStorageStatisticsGraphQLResponse from 'test_fixtures/graphql/usage_quotas/storage/project_storage.query.graphql.json';

export { mockGetProjectStorageStatisticsGraphQLResponse };
export const mockEmptyResponse = { data: { project: null } };

export const projectData = {
  storage: {
    totalUsage: '13.8 MiB',
    storageTypes: [
      {
        storageType: {
          id: 'containerRegistrySize',
          name: 'Container Registry',
          description: 'Gitlab-integrated Docker Container Registry for storing Docker Images.',
          helpPath: '/container_registry',
        },
        value: 3_900_000,
      },
      {
        storageType: {
          id: 'buildArtifactsSize',
          name: 'Job artifacts',
          description: 'Job artifacts created by CI/CD.',
          helpPath: '/build-artifacts',
        },
        value: 400000,
      },
      {
        storageType: {
          id: 'pipelineArtifactsSize',
          name: 'Pipeline artifacts',
          description: 'Pipeline artifacts created by CI/CD.',
          helpPath: '/pipeline-artifacts',
        },
        value: 400000,
      },
      {
        storageType: {
          id: 'lfsObjectsSize',
          name: 'LFS',
          description: 'Audio samples, videos, datasets, and graphics.',
          helpPath: '/lsf-objects',
        },
        value: 4800000,
      },
      {
        storageType: {
          id: 'packagesSize',
          name: 'Packages',
          description: 'Code packages and container images.',
          helpPath: '/packages',
        },
        value: 3800000,
      },
      {
        storageType: {
          id: 'repositorySize',
          name: 'Repository',
          description: 'Git repository.',
          helpPath: '/repository',
        },
        value: 3900000,
      },
      {
        storageType: {
          id: 'snippetsSize',
          name: 'Snippets',
          description: 'Shared bits of code and text.',
          helpPath: '/snippets',
        },
        value: 0,
      },
      {
        storageType: {
          id: 'wikiSize',
          name: 'Wiki',
          description: 'Wiki content.',
          helpPath: '/wiki',
        },
        value: 300000,
      },
    ],
  },
};

export const projectHelpLinks = {
  containerRegistry: '/container_registry',
  usageQuotas: '/usage-quotas',
  buildArtifacts: '/build-artifacts',
  pipelineArtifacts: '/pipeline-artifacts',
  lfsObjects: '/lsf-objects',
  packages: '/packages',
  repository: '/repository',
  snippets: '/snippets',
  wiki: '/wiki',
};

export const defaultProjectProvideValues = {
  projectPath: '/project-path',
  helpLinks: projectHelpLinks,
};
