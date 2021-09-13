export const mockGetProjectStorageCountGraphQLResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/20',
      statistics: {
        buildArtifactsSize: 400000.0,
        pipelineArtifactsSize: 25000.0,
        lfsObjectsSize: 4800000.0,
        packagesSize: 3800000.0,
        repositorySize: 3900000.0,
        snippetsSize: 1200000.0,
        storageSize: 15300000.0,
        uploadsSize: 900000.0,
        wikiSize: 300000.0,
        __typename: 'ProjectStatistics',
      },
      __typename: 'Project',
    },
  },
};

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
    totalUsage: '14.6 MiB',
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
        value: '390.6 KiB',
      },
      {
        storageType: {
          id: 'lfsObjectsSize',
          name: 'LFS Storage',
          description: 'Audio samples, videos, datasets, and graphics.',
          helpPath: '/lsf-objects',
        },
        value: '4.6 MiB',
      },
      {
        storageType: {
          id: 'packagesSize',
          name: 'Packages',
          description: 'Code packages and container images.',
          helpPath: '/packages',
        },
        value: '3.6 MiB',
      },
      {
        storageType: {
          id: 'repositorySize',
          name: 'Repository',
          description: 'Git repository, managed by the Gitaly service.',
          helpPath: '/repository',
        },
        value: '3.7 MiB',
      },
      {
        storageType: {
          id: 'snippetsSize',
          name: 'Snippets',
          description: 'Shared bits of code and text.',
          helpPath: '/snippets',
        },
        value: '1.1 MiB',
      },
      {
        storageType: {
          id: 'uploadsSize',
          name: 'Uploads',
          description: 'File attachments and smaller design graphics.',
          helpPath: '/uploads',
        },
        value: '878.9 KiB',
      },
      {
        storageType: {
          id: 'wikiSize',
          name: 'Wiki',
          description: 'Wiki content.',
          helpPath: '/wiki',
        },
        value: '293.0 KiB',
      },
    ],
  },
};
