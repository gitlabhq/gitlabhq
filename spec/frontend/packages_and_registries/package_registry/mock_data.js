import capitalize from 'lodash/capitalize';

export const packageTags = () => [
  { id: 'gid://gitlab/Packages::Tag/87', name: 'bananas_9', __typename: 'PackageTag' },
  { id: 'gid://gitlab/Packages::Tag/86', name: 'bananas_8', __typename: 'PackageTag' },
  { id: 'gid://gitlab/Packages::Tag/85', name: 'bananas_7', __typename: 'PackageTag' },
];

export const packagePipelines = (extend) => [
  {
    commitPath: '/namespace14/project14/-/commit/b83d6e391c22777fca1ed3012fce84f633d7fed0',
    createdAt: '2020-05-17T14:23:32Z',
    id: 'gid://gitlab/Ci::Pipeline/36',
    path: '/namespace14/project14/-/pipelines/36',
    name: 'project14',
    ref: 'master',
    sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
    project: {
      id: '14',
      name: 'project14',
      webUrl: 'http://gdk.test:3000/namespace14/project14',
      __typename: 'Project',
    },
    user: {
      id: 'user-1',
      name: 'Administrator',
    },
    ...extend,
    __typename: 'Pipeline',
  },
];

export const packageFiles = () => [
  {
    id: 'gid://gitlab/Packages::PackageFile/118',
    fileMd5: 'fileMd5',
    fileName: 'foo-1.0.1.tgz',
    fileSha1: 'be93151dc23ac34a82752444556fe79b32c7a1ad',
    fileSha256: 'fileSha256',
    size: '409600',
    createdAt: '2020-05-17T14:23:32Z',
    downloadPath: 'downloadPath',
    __typename: 'PackageFile',
  },
  {
    id: 'gid://gitlab/Packages::PackageFile/119',
    fileMd5: null,
    fileName: 'foo-1.0.2.tgz',
    fileSha1: 'be93151dc23ac34a82752444556fe79b32c7a1ss',
    fileSha256: null,
    size: '409600',
    createdAt: '2020-05-17T14:23:32Z',
    downloadPath: 'downloadPath',
    __typename: 'PackageFile',
  },
];

export const dependencyLinks = () => [
  {
    dependencyType: 'DEPENDENCIES',
    id: 'gid://gitlab/Packages::DependencyLink/77',
    __typename: 'PackageDependencyLink',
    dependency: {
      id: 'gid://gitlab/Packages::Dependency/3',
      name: 'Ninject.Extensions.Factory',
      versionPattern: '3.3.2',
      __typename: 'PackageDependency',
    },
    metadata: {
      id: 'gid://gitlab/Packages::Nuget::DependencyLinkMetadatum/77',
      targetFramework: '.NETCoreApp3.1',
      __typename: 'NugetDependencyLinkMetadata',
    },
  },
  {
    dependencyType: 'DEPENDENCIES',
    id: 'gid://gitlab/Packages::DependencyLink/78',
    __typename: 'PackageDependencyLink',
    dependency: {
      id: 'gid://gitlab/Packages::Dependency/4',
      name: 'Ninject.Extensions.Factory',
      versionPattern: '3.3.2',
      __typename: 'PackageDependency',
    },
    metadata: {
      id: 'gid://gitlab/Packages::Nuget::DependencyLinkMetadatum/78',
      targetFramework: '.NETCoreApp3.1',
      __typename: 'NugetDependencyLinkMetadata',
    },
  },
];

export const packageProject = () => ({
  id: '1',
  name: 'gitlab-test',
  webUrl: 'http://gdk.test:3000/gitlab-org/gitlab-test',
  __typename: 'Project',
});

export const linksData = {
  _links: {
    webPath: '/gitlab-org/package-15',
  },
};

const userPermissionsData = {
  userPermissions: {
    destroyPackage: true,
  },
};

export const defaultPackageGroupSettings = {
  mavenPackageRequestsForwarding: true,
  npmPackageRequestsForwarding: true,
  pypiPackageRequestsForwarding: true,
  __typename: 'PackageSettings',
};

export const packageVersions = () => [
  {
    createdAt: '2021-08-10T09:33:54Z',
    id: 'gid://gitlab/Packages::Package/243',
    name: '@gitlab-org/package-15',
    status: 'DEFAULT',
    statusMessage: null,
    packageType: 'NPM',
    tags: { nodes: packageTags() },
    version: '1.0.1',
    ...linksData,
    ...userPermissionsData,
    __typename: 'Package',
  },
  {
    createdAt: '2021-08-10T09:33:54Z',
    id: 'gid://gitlab/Packages::Package/244',
    name: '@gitlab-org/package-15',
    status: 'DEFAULT',
    statusMessage: null,
    packageType: 'NPM',
    tags: { nodes: packageTags() },
    version: '1.0.2',
    ...linksData,
    ...userPermissionsData,
    __typename: 'Package',
  },
];

export const packageData = (extend) => ({
  __typename: 'Package',
  id: 'gid://gitlab/Packages::Package/1',
  name: '@gitlab-org/package-15',
  packageType: 'NPM',
  version: '1.0.0',
  createdAt: '2020-05-17T14:23:32Z',
  updatedAt: '2020-08-17T14:23:32Z',
  lastDownloadedAt: '2021-08-17T14:23:32Z',
  status: 'DEFAULT',
  statusMessage: null,
  mavenUrl: 'http://gdk.test:3000/api/v4/projects/1/packages/maven',
  npmUrl: 'http://gdk.test:3000/api/v4/projects/1/packages/npm',
  nugetUrl: 'http://gdk.test:3000/api/v4/projects/1/packages/nuget/index.json',
  composerConfigRepositoryUrl: 'gdk.test/22',
  composerUrl: 'http://gdk.test:3000/api/v4/group/22/-/packages/composer/packages.json',
  conanUrl: 'http://gdk.test:3000/api/v4/projects/1/packages/conan',
  pypiUrl:
    'http://__token__:<your_personal_token>@gdk.test:3000/api/v4/projects/1/packages/pypi/simple',
  publicPackage: false,
  pypiSetupUrl: 'http://gdk.test:3000/api/v4/projects/1/packages/pypi',
  protectionRuleExists: false,
  ...userPermissionsData,
  ...extend,
});

export const conanMetadata = () => ({
  __typename: 'ConanMetadata',
  id: 'conan-1',
  packageChannel: 'stable',
  packageUsername: 'gitlab-org+gitlab-test',
  recipe: 'package-8/1.0.0@gitlab-org+gitlab-test/stable',
  recipePath: 'package-8/1.0.0/gitlab-org+gitlab-test/stable',
});

export const composerMetadata = () => ({
  __typename: 'ComposerMetadata',
  targetSha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
  composerJson: {
    license: 'MIT',
    version: '1.0.0',
  },
});

export const pypiMetadata = () => ({
  __typename: 'PypiMetadata',
  id: 'pypi-1',
  authorEmail: '"C. Schultz" <cschultz@example.com>',
  keywords: 'dog,puppy,voting,election',
  requiredPython: '1.0.0',
  summary: 'A module for collecting votes from beagles.',
});

export const mavenMetadata = () => ({
  __typename: 'MavenMetadata',
  id: 'maven-1',
  appName: 'appName',
  appGroup: 'appGroup',
  appVersion: 'appVersion',
  path: 'path',
});

export const nugetMetadata = () => ({
  __typename: 'NugetMetadata',
  id: 'nuget-1',
  iconUrl: 'iconUrl',
  licenseUrl: 'licenseUrl',
  projectUrl: 'projectUrl',
});

const packageTypeMetadataQueryMapping = {
  CONAN: conanMetadata,
  COMPOSER: composerMetadata,
  PYPI: pypiMetadata,
  MAVEN: mavenMetadata,
  NUGET: nugetMetadata,
};

export const pagination = (extend) => ({
  endCursor: 'eyJpZCI6IjIwNSIsIm5hbWUiOiJteS9jb21wYW55L2FwcC9teS1hcHAifQ',
  hasNextPage: true,
  hasPreviousPage: true,
  startCursor: 'eyJpZCI6IjI0NyIsIm5hbWUiOiJ2ZXJzaW9uX3Rlc3QxIn0',
  __typename: 'PageInfo',
  ...extend,
});

export const packageDetailsQuery = ({ extendPackage = {} } = {}) => ({
  data: {
    package: {
      ...packageData(),
      metadata: {
        ...conanMetadata(),
        ...composerMetadata(),
        ...pypiMetadata(),
        ...mavenMetadata(),
        ...nugetMetadata(),
      },
      project: {
        id: '1',
        path: 'projectPath',
        name: 'gitlab-test',
        fullPath: 'gitlab-test',
        __typename: 'Project',
      },
      tags: {
        nodes: packageTags(),
        __typename: 'PackageTagConnection',
      },
      pipelines: {
        nodes: packagePipelines(),
        __typename: 'PipelineConnection',
      },
      versions: {
        count: packageVersions().length,
      },
      dependencyLinks: {
        nodes: dependencyLinks(),
      },
      __typename: 'PackageDetailsType',
      ...extendPackage,
    },
  },
});

export const groupPackageSettingsQueryForGroup = ({
  packageSettings = defaultPackageGroupSettings,
} = {}) => ({
  data: {
    group: {
      id: 'group-id',
      packageSettings,
      __typename: 'Group',
    },
  },
});

export const groupPackageSettingsQuery = ({
  packageSettings = defaultPackageGroupSettings,
} = {}) => ({
  data: {
    project: {
      id: '1',
      group: {
        id: '1',
        packageSettings,
        __typename: 'Group',
      },
      __typename: 'Project',
    },
  },
});

export const packagePipelinesQuery = (pipelines = packagePipelines()) => ({
  data: {
    package: {
      id: 'gid://gitlab/Packages::Package/111',
      pipelines: {
        nodes: pipelines,
        __typename: 'PipelineConnection',
      },
      __typename: 'PackageDetailsType',
    },
  },
});

export const packageFilesQuery = ({ files = packageFiles(), extendPagination = {} } = {}) => ({
  data: {
    package: {
      id: 'gid://gitlab/Packages::Package/111',
      packageFiles: {
        pageInfo: pagination(extendPagination),
        nodes: files,
        __typename: 'PackageFileConnection',
      },
      __typename: 'PackageDetailsType',
    },
  },
});

export const emptyPackageDetailsQuery = () => ({
  data: {
    package: {
      __typename: 'PackageDetailsType',
    },
  },
});

export const packageMetadataQuery = (packageType) => {
  return {
    data: {
      package: {
        id: 'gid://gitlab/Packages::Package/111',
        packageType,
        metadata: {
          ...packageTypeMetadataQueryMapping[packageType]?.(),
        },
        __typename: 'PackageDetailsType',
      },
    },
  };
};

export const packageVersionsQuery = (versions = packageVersions()) => ({
  data: {
    package: {
      id: 'gid://gitlab/Packages::Package/111',
      versions: {
        count: versions.length,
        nodes: versions,
        pageInfo: pagination(),
        __typename: 'PackageConnection',
      },
      __typename: 'PackageDetailsType',
    },
  },
});

export const emptyPackageVersionsQuery = {
  data: {
    package: {
      id: 'gid://gitlab/Packages::Package/111',
      versions: {
        count: 0,
        nodes: [],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'endCursor',
          startCursor: 'startCursor',
        },
        __typename: 'PackageConnection',
      },
      __typename: 'PackageDetailsType',
    },
  },
};

export const packagesDestroyMutation = () => ({
  data: {
    destroyPackages: {
      errors: [],
    },
  },
});

export const packagesDestroyMutationError = () => ({
  data: {
    destroyPackages: null,
  },
  errors: [
    {
      message:
        "The resource that you are attempting to access does not exist or you don't have permission to perform this action",
      locations: [
        {
          line: 2,
          column: 3,
        },
      ],
      path: ['destroyPackages'],
    },
  ],
});

export const packageDestroyFilesMutation = () => ({
  data: {
    destroyPackageFiles: {
      errors: [],
    },
  },
});

export const packageDestroyFilesMutationError = () => ({
  data: {
    destroyPackageFiles: null,
  },
  errors: [
    {
      message:
        "The resource that you are attempting to access does not exist or you don't have permission to perform this action",
      locations: [
        {
          line: 2,
          column: 3,
        },
      ],
      path: ['destroyPackageFiles'],
    },
  ],
});

export const packagesListQuery = ({ type = 'group', extend = {}, extendPagination = {} } = {}) => ({
  data: {
    [type]: {
      id: '1',
      packages: {
        count: 2,
        nodes: [
          {
            ...packageData(),
            protectionRuleExists: false,
            ...linksData,
            ...(type === 'group' && { project: packageProject() }),
            tags: { nodes: packageTags() },
            pipelines: {
              nodes: packagePipelines(),
            },
          },
          {
            ...packageData(),
            protectionRuleExists: false,
            ...(type === 'group' && { project: packageProject() }),
            tags: { nodes: [] },
            pipelines: { nodes: [] },
            ...linksData,
          },
        ],
        pageInfo: pagination(extendPagination),
        __typename: 'PackageConnection',
      },
      ...extend,
      __typename: capitalize(type),
    },
  },
});

export const errorPackagesListQuery = ({ type = 'group', extend = {} } = {}) => ({
  data: {
    [type]: {
      id: '1',
      packages: {
        ...extend,
        __typename: 'PackageConnection',
      },
      __typename: capitalize(type),
    },
  },
});
