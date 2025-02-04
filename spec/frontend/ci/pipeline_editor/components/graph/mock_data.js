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

export const pipelineDataWithNoNeeds = {
  stages: [
    {
      name: 'build',
      groups: [
        {
          name: 'build_1',
          jobs: [{ script: 'echo hello', stage: 'build' }],
        },
      ],
    },
    {
      name: 'test',
      groups: [
        {
          name: 'test_1',
          jobs: [{ script: 'yarn test', stage: 'test' }],
        },
      ],
    },
  ],
};

export const pipelineData = {
  stages: [
    {
      name: 'build',
      groups: [
        {
          name: 'build_1',
          jobs: [{ script: 'echo hello', stage: 'build' }],
        },
      ],
    },
    {
      name: 'test',
      groups: [
        {
          name: 'test_1',
          jobs: [{ script: 'yarn test', stage: 'test' }],
        },
        {
          name: 'test_2',
          jobs: [{ script: 'yarn karma', stage: 'test' }],
        },
      ],
    },
    {
      name: 'deploy',
      groups: [
        {
          name: 'deploy_1',
          jobs: [{ script: 'yarn magick', stage: 'deploy', needs: ['test_1'] }],
        },
      ],
    },
  ],
};

export const invalidNeedsData = {
  stages: [
    {
      name: 'build',
      groups: [
        {
          name: 'build_1',
          jobs: [{ script: 'echo hello', stage: 'build' }],
        },
      ],
    },
    {
      name: 'test',
      groups: [
        {
          name: 'test_1',
          jobs: [{ script: 'yarn test', stage: 'test' }],
        },
        {
          name: 'test_2',
          jobs: [{ script: 'yarn karma', stage: 'test' }],
        },
      ],
    },
    {
      name: 'deploy',
      groups: [
        {
          name: 'deploy_1',
          jobs: [{ script: 'yarn magick', stage: 'deploy', needs: ['invalid_job'] }],
        },
      ],
    },
  ],
};

export const parallelNeedData = {
  stages: [
    {
      name: 'build',
      groups: [
        {
          name: 'build_1',
          parallel: 3,
          jobs: [
            { script: 'echo hello', stage: 'build', name: 'build_1 1/3' },
            { script: 'echo hello', stage: 'build', name: 'build_1 2/3' },
            { script: 'echo hello', stage: 'build', name: 'build_1 3/3' },
          ],
        },
      ],
    },
    {
      name: 'test',
      groups: [
        {
          name: 'test_1',
          jobs: [{ script: 'yarn test', stage: 'test', needs: ['build_1'], name: 'test_1 1/1' }],
        },
      ],
    },
  ],
};

export const sameStageNeeds = {
  stages: [
    {
      name: 'build',
      groups: [
        {
          name: 'build_1',
          jobs: [{ script: 'echo hello', stage: 'build', name: 'build_1' }],
        },
      ],
    },
    {
      name: 'build',
      groups: [
        {
          name: 'build_2',
          jobs: [{ script: 'yarn test', stage: 'build', needs: ['build_1'] }],
        },
      ],
    },
    {
      name: 'build',
      groups: [
        {
          name: 'build_3',
          jobs: [{ script: 'yarn test', stage: 'build', needs: ['build_2'] }],
        },
      ],
    },
  ],
};

export const largePipelineData = {
  stages: [
    {
      name: 'build',
      groups: [
        {
          name: 'build_1',
          jobs: [{ script: 'echo hello', stage: 'build' }],
        },
        {
          name: 'build_2',
          jobs: [{ script: 'echo hello', stage: 'build' }],
        },
        {
          name: 'build_3',
          jobs: [{ script: 'echo hello', stage: 'build' }],
        },
      ],
    },
    {
      name: 'test',
      groups: [
        {
          name: 'test_1',
          jobs: [{ script: 'yarn test', stage: 'test', needs: ['build_2'] }],
        },
        {
          name: 'test_2',
          jobs: [{ script: 'yarn karma', stage: 'test', needs: ['build_2'] }],
        },
      ],
    },
    {
      name: 'deploy',
      groups: [
        {
          name: 'deploy_1',
          jobs: [{ script: 'yarn magick', stage: 'deploy', needs: ['test_1'] }],
        },
        {
          name: 'deploy_2',
          jobs: [{ script: 'yarn magick', stage: 'deploy', needs: ['build_3'] }],
        },
        {
          name: 'deploy_3',
          jobs: [{ script: 'yarn magick', stage: 'deploy', needs: ['test_2'] }],
        },
      ],
    },
  ],
};

export const singleStageData = {
  stages: [
    {
      name: 'build',
      groups: [
        {
          name: 'build_1',
          jobs: [{ script: 'echo hello', stage: 'build' }],
        },
      ],
    },
  ],
};

export const rootRect = {
  bottom: 463,
  height: 271,
  left: 236,
  right: 1252,
  top: 192,
  width: 1016,
  x: 236,
  y: 192,
};

export const jobRect = {
  bottom: 312,
  height: 24,
  left: 308,
  right: 428,
  top: 288,
  width: 120,
  x: 308,
  y: 288,
};
