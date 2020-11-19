import { createUniqueJobId } from '~/pipelines/utils';

export const yamlString = `stages:
- empty
- build
- test
- deploy
- final

include:
- template: 'Workflows/MergeRequest-Pipelines.gitlab-ci.yml'

build_a:
  stage: build
  script: echo hello
build_b:
  stage: build
  script: echo hello
build_c:
  stage: build
  script: echo hello
build_d:
  stage: Queen
  script: echo hello

test_a:
  stage: test
  script: ls
  needs: [build_a, build_b, build_c]
test_b:
  stage: test
  script: ls
  needs: [build_a, build_b, build_d]
test_c:
  stage: test
  script: ls
  needs: [build_a, build_b, build_c]

deploy_a:
  stage: deploy
  script: echo hello
`;

const jobId1 = createUniqueJobId('build', 'build_1');
const jobId2 = createUniqueJobId('test', 'test_1');
const jobId3 = createUniqueJobId('test', 'test_2');
const jobId4 = createUniqueJobId('deploy', 'deploy_1');

export const pipelineData = {
  stages: [
    {
      name: 'build',
      groups: [
        {
          name: 'build_1',
          jobs: [{ script: 'echo hello', stage: 'build' }],
          id: jobId1,
        },
      ],
    },
    {
      name: 'test',
      groups: [
        {
          name: 'test_1',
          jobs: [{ script: 'yarn test', stage: 'test' }],
          id: jobId2,
        },
        {
          name: 'test_2',
          jobs: [{ script: 'yarn karma', stage: 'test' }],
          id: jobId3,
        },
      ],
    },
    {
      name: 'deploy',
      groups: [
        {
          name: 'deploy_1',
          jobs: [{ script: 'yarn magick', stage: 'deploy' }],
          id: jobId4,
        },
      ],
    },
  ],
  jobs: {
    [jobId1]: {},
    [jobId2]: {},
    [jobId3]: {},
    [jobId4]: {},
  },
};

export const singleStageData = {
  stages: [
    {
      name: 'build',
      groups: [
        {
          name: 'build_1',
          jobs: [{ script: 'echo hello', stage: 'build' }],
          id: jobId1,
        },
      ],
    },
  ],
};
