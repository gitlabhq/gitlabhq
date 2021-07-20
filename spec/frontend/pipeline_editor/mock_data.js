import { CI_CONFIG_STATUS_VALID } from '~/pipeline_editor/constants';
import { unwrapStagesWithNeeds } from '~/pipelines/components/unwrapping_utils';

export const mockProjectNamespace = 'user1';
export const mockProjectPath = 'project1';
export const mockProjectFullPath = `${mockProjectNamespace}/${mockProjectPath}`;
export const mockDefaultBranch = 'main';
export const mockNewBranch = 'new-branch';
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
export const mockBlobContentQueryResponse = {
  data: {
    project: { repository: { blobs: { nodes: [{ rawBlob: mockCiYml }] } } },
  },
};

export const mockBlobContentQueryResponseNoCiFile = {
  data: {
    project: { repository: { blobs: { nodes: [] } } },
  },
};

export const mockBlobContentQueryResponseEmptyCiFile = {
  data: {
    project: { repository: { blobs: { nodes: [{ rawBlob: '' }] } } },
  },
};

const mockJobFields = {
  beforeScript: [],
  afterScript: [],
  environment: null,
  allowFailure: false,
  tags: [],
  when: 'on_success',
  only: { refs: ['branches', 'tags'], __typename: 'CiJobLimitType' },
  except: null,
  needs: { nodes: [], __typename: 'CiConfigNeedConnection' },
  __typename: 'CiConfigJob',
};

// Mock result of the graphql query at:
// app/assets/javascripts/pipeline_editor/graphql/queries/ci_config.graphql
export const mockCiConfigQueryResponse = {
  data: {
    ciConfig: {
      errors: [],
      mergedYaml: mockCiYml,
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
                  size: 1,
                  jobs: {
                    nodes: [
                      {
                        name: 'job_test_1',
                        script: ['echo "test 1"'],
                        ...mockJobFields,
                      },
                    ],
                    __typename: 'CiConfigJobConnection',
                  },
                  __typename: 'CiConfigGroup',
                },
                {
                  name: 'job_test_2',
                  size: 1,
                  jobs: {
                    nodes: [
                      {
                        name: 'job_test_2',
                        script: ['echo "test 2"'],
                        ...mockJobFields,
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
                  size: 1,
                  jobs: {
                    nodes: [
                      {
                        name: 'job_build',
                        script: ['echo "build"'],
                        ...mockJobFields,
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

export const mockNewCommitShaResults = {
  data: {
    project: {
      pipelines: {
        nodes: [
          {
            id: 'gid://gitlab/Ci::Pipeline/1',
            sha: 'd0d56d363d8a3f67a8ab9fc00207d468f30032ca',
            path: `/${mockProjectFullPath}/-/pipelines/488`,
            commitPath: `/${mockProjectFullPath}/-/commit/d0d56d363d8a3f67a8ab9fc00207d468f30032ca`,
          },
          {
            id: 'gid://gitlab/Ci::Pipeline/2',
            sha: 'fcab2ece40b26f428dfa3aa288b12c3c5bdb06aa',
            path: `/${mockProjectFullPath}/-/pipelines/487`,
            commitPath: `/${mockProjectFullPath}/-/commit/fcab2ece40b26f428dfa3aa288b12c3c5bdb06aa`,
          },
          {
            id: 'gid://gitlab/Ci::Pipeline/3',
            sha: '6c16b17c7f94a438ae19a96c285bb49e3c632cf4',
            path: `/${mockProjectFullPath}/-/pipelines/433`,
            commitPath: `/${mockProjectFullPath}/-/commit/6c16b17c7f94a438ae19a96c285bb49e3c632cf4`,
          },
        ],
      },
    },
  },
};

export const mockProjectBranches = {
  data: {
    project: {
      repository: {
        branchNames: [
          'main',
          'develop',
          'production',
          'test',
          'better-feature',
          'feature-abc',
          'update-ci',
          'mock-feature',
          'test-merge-request',
          'staging',
        ],
      },
    },
  },
};

export const mockTotalBranchResults =
  mockProjectBranches.data.project.repository.branchNames.length;

export const mockSearchBranches = {
  data: {
    project: {
      repository: {
        branchNames: ['test', 'better-feature', 'update-ci', 'test-merge-request'],
      },
    },
  },
};

export const mockTotalSearchResults = mockSearchBranches.data.project.repository.branchNames.length;

export const mockEmptySearchBranches = {
  data: {
    project: {
      repository: {
        branchNames: [],
      },
    },
  },
};

export const mockBranchPaginationLimit = 10;
export const mockTotalBranches = 20; // must be greater than mockBranchPaginationLimit to test pagination

export const mockProjectPipeline = {
  pipeline: {
    commitPath: '/-/commit/aabbccdd',
    id: 'gid://gitlab/Ci::Pipeline/118',
    iid: '28',
    shortSha: mockCommitSha,
    status: 'SUCCESS',
    detailedStatus: {
      detailsPath: '/root/sample-ci-project/-/pipelines/118"',
      group: 'success',
      icon: 'status_success',
      text: 'passed',
    },
  },
};

export const mockLintResponse = {
  valid: true,
  mergedYaml: mockCiYml,
  status: CI_CONFIG_STATUS_VALID,
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
      except: { refs: ['main@gitlab-org/gitlab', '/^release/.*$/@gitlab-org/gitlab'] },
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
      except: { refs: ['main@gitlab-org/gitlab', '/^release/.*$/@gitlab-org/gitlab'] },
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
    except: { refs: ['main@gitlab-org/gitlab', '/^release/.*$/@gitlab-org/gitlab'] },
  },
];

export const mockErrors = [
  '"job_1 job: chosen stage does not exist; available stages are .pre, build, test, deploy, .post"',
];

export const mockWarnings = [
  '"jobs:multi_project_job may allow multiple pipelines to run for a single action due to `rules:when` clause with no `workflow:rules` - read more: https://docs.gitlab.com/ee/ci/troubleshooting.html#pipeline-warnings"',
];
