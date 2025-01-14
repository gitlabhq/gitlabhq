import { CI_CONFIG_STATUS_INVALID, CI_CONFIG_STATUS_VALID } from '~/ci/pipeline_editor/constants';
import { unwrapStagesWithNeeds } from '~/ci/pipeline_details/utils/unwrapping_utils';
import { DOCS_URL_IN_EE_DIR } from 'jh_else_ce/lib/utils/url_utility';

export const commonOptions = {
  ciConfigPath: '/ci/config',
  ciExamplesHelpPagePath: 'help/ci/examples',
  ciHelpPagePath: 'help/ci/',
  ciLintPath: 'ci/lint',
  ciTroubleshootingPath: 'help/troubleshoot',
  defaultBranch: 'main',
  emptyStateIllustrationPath: 'illustrations/svg',
  helpPaths: '/ads',
  includesHelpPagePath: 'help/includes',
  needsHelpPagePath: 'help/ci/needs',
  newMergeRequestPath: 'merge_request/new',
  pipelinePagePath: '/pipelines/1',
  projectFullPath: 'root/my-project',
  projectNamespace: 'root',
  simulatePipelineHelpPagePath: 'help/ci/simulate',
  totalBranches: '10',
  usesExternalConfig: 'false',
  validateTabIllustrationPath: 'illustrations/tab',
  ymlHelpPagePath: 'help/ci/yml',
};

export const editorDatasetOptions = {
  initialBranchName: 'production',
  pipelineEtag: 'pipelineEtag',
  ciCatalogPath: '/explore/catalog',
  ...commonOptions,
};

export const expectedInjectValues = {
  ...commonOptions,
  usesExternalConfig: false,
  totalBranches: 10,
};

export const mockProjectNamespace = 'user1';
export const mockProjectPath = 'project1';
export const mockProjectFullPath = `${mockProjectNamespace}/${mockProjectPath}`;
export const mockDefaultBranch = 'main';
export const mockNewBranch = 'new-branch';
export const mockNewMergeRequestPath = '/-/merge_requests/new';
export const mockCiLintPath = '/-/ci/lint';
export const mockCommitSha = 'aabbccdd';
export const mockCommitNextSha = 'eeffgghh';
export const mockIncludesHelpPagePath = '/-/includes/help';
export const mockLintHelpPagePath = '/-/lint-help';
export const mockCiTroubleshootingPath = '/-/pipeline-editor/troubleshoot';
export const mockSimulatePipelineHelpPagePath = '/-/simulate-pipeline-help';
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

export const mockCiTemplateQueryResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      ciTemplate: {
        content: mockCiYml,
      },
    },
  },
};

export const mockBlobContentQueryResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      repository: { blobs: { nodes: [{ id: 'blob-1', rawBlob: mockCiYml }] } },
    },
  },
};

export const mockBlobContentQueryResponseNoCiFile = {
  data: {
    project: { id: 'gid://gitlab/Project/1', repository: { blobs: { nodes: [] } } },
  },
};

export const mockBlobContentQueryResponseEmptyCiFile = {
  data: {
    project: { id: 'gid://gitlab/Project/1', repository: { blobs: { nodes: [{ rawBlob: '' }] } } },
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

export const mockIncludesWithBlob = {
  location: 'test-include.yml',
  type: 'local',
  blob: 'http://gdk.test:3000/root/upstream/-/blob/dd54f00bb3645f8ddce7665d2ffb3864540399cb/test-include.yml',
  raw: 'http://gdk.test:3000/root/upstream/-/raw/dd54f00bb3645f8ddce7665d2ffb3864540399cb/test-include.yml',
  __typename: 'CiConfigInclude',
};

export const mockDefaultIncludes = {
  location: 'npm.gitlab-ci.yml',
  type: 'template',
  blob: null,
  raw: 'https://gitlab.com/gitlab-org/gitlab/-/raw/master/lib/gitlab/ci/templates/npm.gitlab-ci.yml',
  __typename: 'CiConfigInclude',
};

export const mockIncludes = [
  mockDefaultIncludes,
  mockIncludesWithBlob,
  {
    location: 'a_really_really_long_name_for_includes_file.yml',
    type: 'local',
    blob: 'http://gdk.test:3000/root/upstream/-/blob/dd54f00bb3645f8ddce7665d2ffb3864540399cb/a_really_really_long_name_for_includes_file.yml',
    raw: 'http://gdk.test:3000/root/upstream/-/raw/dd54f00bb3645f8ddce7665d2ffb3864540399cb/a_really_really_long_name_for_includes_file.yml',
    __typename: 'CiConfigInclude',
  },
];

// Mock result of the graphql query at:
// app/assets/javascripts/ci/pipeline_editor/graphql/queries/ci_config.graphql
export const mockCiConfigQueryResponse = {
  data: {
    ciConfig: {
      errors: [],
      includes: mockIncludes,
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
                  id: 'group-1',
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
                  id: 'group-2',
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

export const mockCommitShaResults = {
  data: {
    project: {
      id: '1',
      repository: {
        tree: {
          lastCommit: {
            id: 'commit-1',
            sha: mockCommitSha,
          },
        },
      },
    },
  },
};

export const mockNewCommitShaResults = {
  data: {
    project: {
      id: '1',
      repository: {
        tree: {
          lastCommit: {
            id: 'commit-1',
            sha: 'eeff1122',
          },
        },
      },
    },
  },
};

export const mockEmptyCommitShaResults = {
  data: {
    project: {
      id: '1',
      repository: {
        tree: {
          lastCommit: {
            id: 'commit-1',
            sha: '',
          },
        },
      },
    },
  },
};

export const generateMockProjectBranches = (prefix = '') => ({
  data: {
    project: {
      id: '1',
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
        ].map((branch) => `${prefix}${branch}`),
      },
    },
  },
});

export const mockTotalBranchResults =
  generateMockProjectBranches().data.project.repository.branchNames.length;

export const mockSearchBranches = {
  data: {
    project: {
      id: '1',
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
      id: '1',
      repository: {
        branchNames: [],
      },
    },
  },
};

export const mockBranchPaginationLimit = 10;
export const mockTotalBranches = 20; // must be greater than mockBranchPaginationLimit to test pagination

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

export const mockLintResponseWithoutMerged = {
  valid: false,
  status: CI_CONFIG_STATUS_INVALID,
  errors: ['error'],
  warnings: [],
  jobs: [],
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
  '"job_1 job: chosen stage test does not exist; available stages are .pre, build, test, deploy, .post"',
];

export const mockWarnings = [
  `"jobs:multi_project_job may allow multiple pipelines to run for a single action due to \`rules:when\` clause with no \`workflow:rules\` - read more: ${DOCS_URL_IN_EE_DIR}/ci/troubleshooting.html#pipeline-warnings"`,
];

export const mockCommitCreateResponse = {
  data: {
    commitCreate: {
      __typename: 'CommitCreatePayload',
      errors: [],
      commit: {
        __typename: 'Commit',
        id: 'commit-1',
        sha: mockCommitNextSha,
      },
      commitPipelinePath: '',
    },
  },
};

export const mockRunnersTagsQueryResponse = {
  data: {
    runners: {
      nodes: [
        {
          id: 'gid://gitlab/Ci::Runner/1',
          tagList: ['tag1', 'tag2'],
          __typename: 'CiRunner',
        },
        {
          id: 'gid://gitlab/Ci::Runner/2',
          tagList: ['tag2', 'tag3'],
          __typename: 'CiRunner',
        },
        {
          id: 'gid://gitlab/Ci::Runner/3',
          tagList: ['tag2', 'tag4'],
          __typename: 'CiRunner',
        },
        {
          id: 'gid://gitlab/Ci::Runner/4',
          tagList: [],
          __typename: 'CiRunner',
        },
      ],
      __typename: 'CiRunnerConnection',
    },
  },
};

export const mockCommitCreateResponseNewEtag = {
  data: {
    commitCreate: {
      __typename: 'CommitCreatePayload',
      errors: [],
      commit: {
        __typename: 'Commit',
        id: 'commit-2',
        sha: mockCommitNextSha,
      },
      commitPipelinePath: '/api/graphql:pipelines/sha/550ceace1acd373c84d02bd539cb9d4614f786db',
    },
  },
};
