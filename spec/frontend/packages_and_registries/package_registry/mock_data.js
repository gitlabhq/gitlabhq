export const packageTags = () => [
  { id: 'gid://gitlab/Packages::Tag/87', name: 'bananas_9', __typename: 'PackageTag' },
  { id: 'gid://gitlab/Packages::Tag/86', name: 'bananas_8', __typename: 'PackageTag' },
  { id: 'gid://gitlab/Packages::Tag/85', name: 'bananas_7', __typename: 'PackageTag' },
];

export const packagePipelines = (extend) => [
  {
    commitPath: '/namespace14/project14/-/commit/b83d6e391c22777fca1ed3012fce84f633d7fed0',
    createdAt: '2020-08-17T14:23:32Z',
    id: 'gid://gitlab/Ci::Pipeline/36',
    path: '/namespace14/project14/-/pipelines/36',
    name: 'project14',
    ref: 'master',
    sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
    project: {
      name: 'project14',
      webUrl: 'http://gdk.test:3000/namespace14/project14',
      __typename: 'Project',
    },
    user: {
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
    createdAt: '2020-08-17T14:23:32Z',
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
    createdAt: '2020-08-17T14:23:32Z',
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

export const packageVersions = () => [
  {
    createdAt: '2021-08-10T09:33:54Z',
    id: 'gid://gitlab/Packages::Package/243',
    name: '@gitlab-org/package-15',
    status: 'DEFAULT',
    tags: { nodes: packageTags() },
    version: '1.0.1',
    __typename: 'Package',
  },
  {
    createdAt: '2021-08-10T09:33:54Z',
    id: 'gid://gitlab/Packages::Package/244',
    name: '@gitlab-org/package-15',
    status: 'DEFAULT',
    tags: { nodes: packageTags() },
    version: '1.0.2',
    __typename: 'Package',
  },
];

export const packageData = (extend) => ({
  id: 'gid://gitlab/Packages::Package/111',
  name: '@gitlab-org/package-15',
  packageType: 'NPM',
  version: '1.0.0',
  createdAt: '2020-08-17T14:23:32Z',
  updatedAt: '2020-08-17T14:23:32Z',
  status: 'DEFAULT',
  ...extend,
});

export const conanMetadata = () => ({
  packageChannel: 'stable',
  packageUsername: 'gitlab-org+gitlab-test',
  recipe: 'package-8/1.0.0@gitlab-org+gitlab-test/stable',
  recipePath: 'package-8/1.0.0/gitlab-org+gitlab-test/stable',
});

export const composerMetadata = () => ({
  targetSha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
  composerJson: {
    license: 'MIT',
    version: '1.0.0',
  },
});

export const pypyMetadata = () => ({
  requiredPython: '1.0.0',
});

export const mavenMetadata = () => ({
  appName: 'appName',
  appGroup: 'appGroup',
  appVersion: 'appVersion',
  path: 'path',
});

export const nugetMetadata = () => ({
  iconUrl: 'iconUrl',
  licenseUrl: 'licenseUrl',
  projectUrl: 'projectUrl',
});

export const packageDetailsQuery = (extendPackage) => ({
  data: {
    package: {
      ...packageData(),
      metadata: {
        ...conanMetadata(),
        ...composerMetadata(),
        ...pypyMetadata(),
        ...mavenMetadata(),
        ...nugetMetadata(),
      },
      project: {
        path: 'projectPath',
      },
      tags: {
        nodes: packageTags(),
        __typename: 'PackageTagConnection',
      },
      pipelines: {
        nodes: packagePipelines(),
        __typename: 'PipelineConnection',
      },
      packageFiles: {
        nodes: packageFiles(),
        __typename: 'PackageFileConnection',
      },
      versions: {
        nodes: packageVersions(),
        __typename: 'PackageConnection',
      },
      dependencyLinks: {
        nodes: dependencyLinks(),
      },
      __typename: 'PackageDetailsType',
      ...extendPackage,
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

export const packageDestroyMutation = () => ({
  data: {
    destroyPackage: {
      errors: [],
    },
  },
});

export const packageDestroyMutationError = () => ({
  data: {
    destroyPackage: null,
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
      path: ['destroyPackage'],
    },
  ],
});

export const packageDestroyFileMutation = () => ({
  data: {
    destroyPackageFile: {
      errors: [],
    },
  },
});
export const packageDestroyFileMutationError = () => ({
  data: {
    destroyPackageFile: null,
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
      path: ['destroyPackageFile'],
    },
  ],
});
