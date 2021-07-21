export const packageTags = () => [
  { id: 'gid://gitlab/Packages::Tag/87', name: 'bananas_9', __typename: 'PackageTag' },
  { id: 'gid://gitlab/Packages::Tag/86', name: 'bananas_8', __typename: 'PackageTag' },
  { id: 'gid://gitlab/Packages::Tag/85', name: 'bananas_7', __typename: 'PackageTag' },
];

export const packagePipelines = (extend) => [
  {
    project: {
      name: 'project14',
      webUrl: 'http://gdk.test:3000/namespace14/project14',
      __typename: 'Project',
    },
    ...extend,
    __typename: 'Pipeline',
  },
];

export const packageFiles = () => [
  {
    id: 'gid://gitlab/Packages::PackageFile/118',
    fileMd5: null,
    fileName: 'foo-1.0.1.tgz',
    fileSha1: 'be93151dc23ac34a82752444556fe79b32c7a1ad',
    fileSha256: null,
    size: '409600',
    __typename: 'PackageFile',
  },
  {
    id: 'gid://gitlab/Packages::PackageFile/119',
    fileMd5: null,
    fileName: 'foo-1.0.2.tgz',
    fileSha1: 'be93151dc23ac34a82752444556fe79b32c7a1ss',
    fileSha256: null,
    size: '409600',
    __typename: 'PackageFile',
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

export const packageDetailsQuery = () => ({
  data: {
    package: {
      ...packageData(),
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
      __typename: 'PackageDetailsType',
    },
  },
});
