import mockGetProjectStorageStatisticsGraphQLResponse from 'test_fixtures/graphql/usage_quotas/storage/project_storage.query.graphql.json';

export { mockGetProjectStorageStatisticsGraphQLResponse };
export const mockEmptyResponse = { data: { project: null } };

export const projectData = {
  storage: {
    totalUsage: '13.4 MiB',
    storageTypes: [
      {
        storageType: {
          id: 'containerRegistry',
          name: 'Container Registry',
          description: 'Gitlab-integrated Docker Container Registry for storing Docker Images.',
          helpPath: '/container_registry',
          detailsPath: 'http://localhost/frontend-fixtures/builds-project/container_registry',
        },
        value: 3900000,
      },
      {
        storageType: {
          id: 'buildArtifacts',
          name: 'Job artifacts',
          description: 'Job artifacts created by CI/CD.',
          helpPath: '/build-artifacts',
          detailsPath: 'http://localhost/frontend-fixtures/builds-project/-/artifacts',
        },
        value: 400000,
      },
      {
        storageType: {
          id: 'pipelineArtifacts',
          name: 'Pipeline artifacts',
          description: 'Pipeline artifacts created by CI/CD.',
          helpPath: '/pipeline-artifacts',
        },
        value: 400000,
      },
      {
        storageType: {
          id: 'lfsObjects',
          name: 'LFS',
          description: 'Audio samples, videos, datasets, and graphics.',
          helpPath: '/lsf-objects',
        },
        value: 4800000,
      },
      {
        storageType: {
          id: 'packages',
          name: 'Packages',
          description: 'Code packages and container images.',
          helpPath: '/packages',
          detailsPath: 'http://localhost/frontend-fixtures/builds-project/-/packages',
        },
        value: 3800000,
      },
      {
        storageType: {
          id: 'repository',
          name: 'Repository',
          description: 'Git repository.',
          helpPath: '/repository',
          detailsPath: 'http://localhost/frontend-fixtures/builds-project/-/tree/master',
        },
        value: 3900000,
      },
      {
        storageType: {
          id: 'snippets',
          name: 'Snippets',
          description: 'Shared bits of code and text.',
          helpPath: '/snippets',
          detailsPath: 'http://localhost/frontend-fixtures/builds-project/-/snippets',
        },
        value: 0,
      },
      {
        storageType: {
          id: 'wiki',
          name: 'Wiki',
          description: 'Wiki content.',
          helpPath: '/wiki',
          detailsPath: 'http://localhost/frontend-fixtures/builds-project/-/wikis/pages',
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
