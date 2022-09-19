export const harborImageDetailEmptyResponse = {
  data: null,
};

export const MOCK_SHA_DIGEST = 'mock_sha_digest_value';

export const harborImageDetailResponse = {
  artifactCount: 10,
  creationTime: '2022-03-02T06:35:53.205Z',
  id: 25,
  name: 'shao/flinkx',
  projectId: 21,
  pullCount: 0,
  updateTime: '2022-03-02T06:35:53.205Z',
  location: 'demo.harbor.com/gitlab-cn/build/cng-images/gitlab-kas',
};

export const harborArtifactsResponse = [
  {
    id: 1,
    digest: `sha256:${MOCK_SHA_DIGEST}`,
    size: 773928,
    push_time: '2022-05-19T15:54:47.821Z',
    tags: ['latest'],
  },
];

export const harborArtifactsList = [
  {
    id: 1,
    digest: `sha256:${MOCK_SHA_DIGEST}`,
    size: 773928,
    pushTime: '2022-05-19T15:54:47.821Z',
    tags: ['latest'],
  },
];

export const harborTagsResponse = [
  {
    repository_id: 4,
    artifact_id: 5,
    id: 4,
    name: 'latest',
    pull_time: '0001-01-01T00:00:00.000Z',
    push_time: '2022-05-27T18:21:27.903Z',
    signed: false,
    immutable: false,
  },
];

export const harborTagsList = [
  {
    repositoryId: 4,
    artifactId: 5,
    id: 4,
    name: 'latest',
    pullTime: '0001-01-01T00:00:00.000Z',
    pushTime: '2022-05-27T18:21:27.903Z',
    signed: false,
    immutable: false,
  },
];

export const defaultConfig = {
  noContainersImage: 'noContainersImage',
  repositoryUrl: 'demo.harbor.com',
  harborIntegrationProjectName: 'test-project',
  projectName: 'Flight',
  endpoint: '/flightjs/Flight/-/harbor/repositories',
  connectionError: false,
  invalidPathError: false,
  isGroupPage: false,
  containersErrorImage: 'containersErrorImage',
};

export const defaultFullPath = 'flightjs/Flight';

export const harborImagesResponse = [
  {
    id: 1,
    name: 'nginx/nginx',
    artifact_count: 1,
    creation_time: '2022-05-29T10:07:16.812Z',
    update_time: '2022-05-29T10:07:16.812Z',
    project_id: 4,
    pull_count: 0,
    location: 'https://demo.goharbor.io/harbor/projects/4/repositories/nginx',
  },
];

export const harborImagesList = [
  {
    id: 1,
    name: 'nginx/nginx',
    artifactCount: 1,
    creationTime: '2022-05-29T10:07:16.812Z',
    updateTime: '2022-05-29T10:07:16.812Z',
    projectId: 4,
    pullCount: 0,
    location: 'https://demo.goharbor.io/harbor/projects/4/repositories/nginx',
  },
];

export const dockerCommands = {
  dockerBuildCommand: 'foofoo',
  dockerPushCommand: 'barbar',
  dockerLoginCommand: 'bazbaz',
};

export const mockArtifactDetail = {
  project: 'test-project',
  image: 'test-repository',
  digest: `sha256:${MOCK_SHA_DIGEST}`,
};
