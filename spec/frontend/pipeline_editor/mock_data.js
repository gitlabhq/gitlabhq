import { CI_CONFIG_STATUS_VALID } from '~/pipeline_editor/constants';
import { unwrapStagesWithNeeds } from '~/pipelines/components/unwrapping_utils';

export const mockProjectNamespace = 'user1';
export const mockProjectPath = 'project1';
export const mockProjectFullPath = `${mockProjectNamespace}/${mockProjectPath}`;
export const mockDefaultBranch = 'master';
export const mockNewMergeRequestPath = '/-/merge_requests/new';
export const mockCommitSha = 'aabbccdd';
export const mockCommitNextSha = 'eeffgghh';
export const mockLintHelpPagePath = '/-/lint-help';
export const mockYmlHelpPagePath = '/-/yml-help';
export const mockCommitMessage = 'My commit message';

export const mockCiConfigPath = '.gitlab-ci.yml';
export const mockCiYml = `
stages:
  - test
  - build

job_test_1:
  stage: test
  script:
    - echo "test 1"

job_test_2:
  stage: test
  script:
    - echo "test 2"

job_build:
  stage: build
  script: 
    - echo "build"
  needs: ["job_test_2"]
`;

export const mockCiConfigQueryResponse = {
  data: {
    ciConfig: {
      errors: [],
      status: CI_CONFIG_STATUS_VALID,
      stages: {
        __typename: 'CiConfigStageConnection',
        nodes: [
          {
            name: 'test',
            groups: {
              nodes: [
                {
                  name: 'job_test_1',
                  jobs: {
                    nodes: [
                      {
                        name: 'job_test_1',
                        needs: { nodes: [], __typename: 'CiConfigNeedConnection' },
                        __typename: 'CiConfigJob',
                      },
                    ],
                    __typename: 'CiConfigJobConnection',
                  },
                  __typename: 'CiConfigGroup',
                },
                {
                  name: 'job_test_2',
                  jobs: {
                    nodes: [
                      {
                        name: 'job_test_2',
                        needs: { nodes: [], __typename: 'CiConfigNeedConnection' },
                        __typename: 'CiConfigJob',
                      },
                    ],
                    __typename: 'CiConfigJobConnection',
                  },
                  __typename: 'CiConfigGroup',
                },
              ],
              __typename: 'CiConfigGroupConnection',
            },
            __typename: 'CiConfigStage',
          },
          {
            name: 'build',
            groups: {
              nodes: [
                {
                  name: 'job_build',
                  jobs: {
                    nodes: [
                      {
                        name: 'job_build',
                        needs: {
                          nodes: [{ name: 'job_test_2', __typename: 'CiConfigNeed' }],
                          __typename: 'CiConfigNeedConnection',
                        },
                        __typename: 'CiConfigJob',
                      },
                    ],
                    __typename: 'CiConfigJobConnection',
                  },
                  __typename: 'CiConfigGroup',
                },
              ],
              __typename: 'CiConfigGroupConnection',
            },
            __typename: 'CiConfigStage',
          },
        ],
      },
      __typename: 'CiConfig',
    },
  },
};

export const mergeUnwrappedCiConfig = (mergedConfig) => {
  const { ciConfig } = mockCiConfigQueryResponse.data;
  return {
    ...ciConfig,
    stages: unwrapStagesWithNeeds(ciConfig.stages.nodes),
    ...mergedConfig,
  };
};

export const mockLintResponse = {
  valid: true,
  errors: [],
  warnings: [],
  jobs: [
    {
      name: 'job_1',
      stage: 'test',
      before_script: ["echo 'before script 1'"],
      script: ["echo 'script 1'"],
      after_script: ["echo 'after script 1"],
      tag_list: ['tag 1'],
      environment: 'prd',
      when: 'on_success',
      allow_failure: false,
      only: null,
      except: { refs: ['master@gitlab-org/gitlab', '/^release/.*$/@gitlab-org/gitlab'] },
    },
    {
      name: 'job_2',
      stage: 'test',
      before_script: ["echo 'before script 2'"],
      script: ["echo 'script 2'"],
      after_script: ["echo 'after script 2"],
      tag_list: ['tag 2'],
      environment: 'stg',
      when: 'on_success',
      allow_failure: true,
      only: { refs: ['web', 'chat', 'pushes'] },
      except: { refs: ['master@gitlab-org/gitlab', '/^release/.*$/@gitlab-org/gitlab'] },
    },
  ],
};

export const mockJobs = [
  {
    name: 'job_1',
    stage: 'build',
    beforeScript: [],
    script: ["echo 'Building'"],
    afterScript: [],
    tagList: [],
    environment: null,
    when: 'on_success',
    allowFailure: true,
    only: { refs: ['web', 'chat', 'pushes'] },
    except: null,
  },
  {
    name: 'multi_project_job',
    stage: 'test',
    beforeScript: [],
    script: [],
    afterScript: [],
    tagList: [],
    environment: null,
    when: 'on_success',
    allowFailure: false,
    only: { refs: ['branches', 'tags'] },
    except: null,
  },
  {
    name: 'job_2',
    stage: 'test',
    beforeScript: ["echo 'before script'"],
    script: ["echo 'script'"],
    afterScript: ["echo 'after script"],
    tagList: [],
    environment: null,
    when: 'on_success',
    allowFailure: false,
    only: { refs: ['branches@gitlab-org/gitlab'] },
    except: { refs: ['master@gitlab-org/gitlab', '/^release/.*$/@gitlab-org/gitlab'] },
  },
];

export const mockErrors = [
  '"job_1 job: chosen stage does not exist; available stages are .pre, build, test, deploy, .post"',
];

export const mockWarnings = [
  '"jobs:multi_project_job may allow multiple pipelines to run for a single action due to `rules:when` clause with no `workflow:rules` - read more: https://docs.gitlab.com/ee/ci/troubleshooting.html#pipeline-warnings"',
];
