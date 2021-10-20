import mockGetProjectStorageCountGraphQLResponse from 'test_fixtures/graphql/projects/storage_counter/project_storage.query.graphql.json';

export { mockGetProjectStorageCountGraphQLResponse };

export const mockEmptyResponse = { data: { project: null } };

export const defaultProvideValues = {
  projectPath: '/project-path',
  helpLinks: {
    usageQuotasHelpPagePath: '/usage-quotas',
    buildArtifactsHelpPagePath: '/build-artifacts',
    lfsObjectsHelpPagePath: '/lsf-objects',
    packagesHelpPagePath: '/packages',
    repositoryHelpPagePath: '/repository',
    snippetsHelpPagePath: '/snippets',
    uploadsHelpPagePath: '/uploads',
    wikiHelpPagePath: '/wiki',
  },
};

export const projectData = {
  storage: {
    totalUsage: '13.8 MiB',
    storageTypes: [
      {
        storageType: {
          id: 'buildArtifactsSize',
          name: 'Artifacts',
          description: 'Pipeline artifacts and job artifacts, created with CI/CD.',
          warningMessage:
            'There is a known issue with Artifact storage where the total could be incorrect for some projects. More details and progress are available in %{warningLinkStart}the epic%{warningLinkEnd}.',
          helpPath: '/build-artifacts',
        },
        value: 400000,
      },
      {
        storageType: {
          id: 'lfsObjectsSize',
          name: 'LFS Storage',
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
          description: 'Git repository, managed by the Gitaly service.',
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
          id: 'uploadsSize',
          name: 'Uploads',
          description: 'File attachments and smaller design graphics.',
          helpPath: '/uploads',
        },
        value: 900000,
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
