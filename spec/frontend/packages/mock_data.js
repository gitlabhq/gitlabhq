const _links = {
  web_path: 'foo',
  delete_api_path: 'bar',
};

export const mockPipelineInfo = {
  id: 1,
  ref: 'branch-name',
  sha: 'sha-baz',
  user: {
    name: 'foo',
  },
  project: {
    name: 'foo-project',
    web_url: 'foo-project-link',
    commit_url: 'foo-commit-link',
    pipeline_url: 'foo-pipeline-link',
  },
  created_at: '2015-12-10',
};

export const mavenPackage = {
  created_at: '2015-12-10',
  id: 1,
  maven_metadatum: {
    app_group: 'com.test.app',
    app_name: 'test-app',
    app_version: '1.0-SNAPSHOT',
  },
  name: 'Test package',
  package_type: 'maven',
  project_path: 'foo/bar/baz',
  projectPathName: 'foo/bar/baz',
  project_id: 1,
  updated_at: '2015-12-10',
  version: '1.0.0',
  _links,
};

export const mavenFiles = [
  {
    created_at: '2015-12-10',
    file_name: 'File one',
    id: 1,
    size: 100,
    download_path: '/-/package_files/1/download',
  },
  {
    created_at: '2015-12-10',
    file_name: 'File two',
    id: 2,
    size: 200,
    download_path: '/-/package_files/2/download',
  },
];

export const npmPackage = {
  created_at: '2015-12-10',
  id: 2,
  name: '@Test/package',
  package_type: 'npm',
  project_path: 'foo/bar/baz',
  projectPathName: 'foo/bar/baz',
  project_id: 1,
  updated_at: '2015-12-10',
  version: '',
  versions: [],
  _links,
  pipeline: mockPipelineInfo,
};

export const npmFiles = [
  {
    created_at: '2015-12-10',
    file_name: '@test/test-package-1.0.0.tgz',
    id: 2,
    size: 200,
    download_path: '/-/package_files/2/download',
    pipelines: [
      { id: 1, project: { commit_url: 'http://foo.bar' }, git_commit_message: 'foo bar baz?' },
    ],
    file_sha256: 'file_sha256',
    file_md5: 'file_md5',
    file_sha1: 'file_sha1',
  },
];

export const conanPackage = {
  conan_metadatum: {
    package_channel: 'stable',
    package_username: 'conan+conan-package',
  },
  conan_package_name: 'conan-package',
  created_at: '2015-12-10',
  id: 3,
  name: 'conan-package/1.0.0@conan+conan-package/stable',
  project_path: 'foo/bar/baz',
  projectPathName: 'foo/bar/baz',
  package_files: [],
  package_type: 'conan',
  project_id: 1,
  updated_at: '2015-12-10',
  version: '1.0.0',
  _links,
};

export const dependencyLinks = {
  withoutFramework: { name: 'Moqi', version_pattern: '2.5.6' },
  withoutVersion: { name: 'Castle.Core', version_pattern: '' },
  fullLink: {
    name: 'Test.Dependency',
    version_pattern: '2.3.7',
    target_framework: '.NETStandard2.0',
  },
  anotherFullLink: {
    name: 'Newtonsoft.Json',
    version_pattern: '12.0.3',
    target_framework: '.NETStandard2.0',
  },
};

export const nugetPackage = {
  created_at: '2015-12-10',
  id: 4,
  name: 'NugetPackage1',
  package_files: [],
  package_type: 'nuget',
  project_id: 1,
  tags: [],
  updated_at: '2015-12-10',
  version: '1.0.0',
  dependency_links: Object.values(dependencyLinks),
  nuget_metadatum: {
    icon_url: 'fake-icon',
    project_url: 'project-foo-url',
    license_url: 'license-foo-url',
  },
};

export const rubygemsPackage = {
  created_at: '2015-12-10',
  id: 4,
  name: 'RubyGem1',
  package_files: [],
  package_type: 'rubygems',
  project_id: 1,
  tags: [],
  updated_at: '2015-12-10',
  version: '1.0.0',
  rubygems_metadatum: {
    author: 'Fake Name',
    summary: 'My gem',
    email: 'tanuki@fake.com',
  },
};

export const pypiPackage = {
  created_at: '2015-12-10',
  id: 5,
  name: 'PyPiPackage',
  package_files: [],
  package_type: 'pypi',
  project_id: 1,
  tags: [],
  updated_at: '2015-12-10',
  version: '1.0.0',
};

export const composerPackage = {
  created_at: '2015-12-10',
  id: 5,
  name: 'ComposerPackage',
  package_files: [],
  package_type: 'composer',
  project_id: 1,
  tags: [],
  updated_at: '2015-12-10',
  version: '1.0.0',
};

export const terraformModule = {
  created_at: '2015-12-10',
  id: 2,
  name: 'Test/system-22',
  package_type: 'terraform_module',
  project_path: 'foo/bar/baz',
  projectPathName: 'foo/bar/baz',
  project_id: 1,
  updated_at: '2015-12-10',
  version: '0.1',
  versions: [],
  _links,
};

export const mockTags = [
  {
    name: 'foo-1',
  },
  {
    name: 'foo-2',
  },
  {
    name: 'foo-3',
  },
  {
    name: 'foo-4',
  },
];

export const packageList = [mavenPackage, { ...npmPackage, tags: mockTags }, conanPackage];
