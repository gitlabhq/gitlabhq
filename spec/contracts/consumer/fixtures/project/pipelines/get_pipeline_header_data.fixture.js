import { Matchers } from '@pact-foundation/pact';
import {
  JOB_STATUSES,
  PIPELINE_GROUPS,
  PIPELINE_STATUSES,
  PIPELINE_TEXTS,
  URL,
  URL_PATH,
} from '../../../helpers/common_regex_patterns';

const body = {
  data: {
    project: {
      id: Matchers.string('gid://gitlab/Project/278964'),
      pipeline: {
        id: Matchers.string('gid://gitlab/Ci::Pipeline/577266584'),
        iid: Matchers.string('1175084'),
        status: Matchers.term({
          matcher: JOB_STATUSES,
          generate: 'RUNNING',
        }),
        retryable: Matchers.boolean(false),
        cancelable: Matchers.boolean(true),
        userPermissions: {
          destroyPipeline: Matchers.boolean(false),
          updatePipeline: Matchers.boolean(true),
        },
        detailedStatus: {
          id: Matchers.string('running-577266584-577266584'),
          detailsPath: Matchers.term({
            matcher: URL_PATH,
            generate: '/gitlab-org/gitlab/-/pipelines/577266584',
          }),
          icon: Matchers.term({
            matcher: PIPELINE_STATUSES,
            generate: 'status_running',
          }),
          group: Matchers.term({
            matcher: PIPELINE_GROUPS,
            generate: 'running',
          }),
          text: Matchers.term({
            matcher: PIPELINE_TEXTS,
            generate: 'Running',
          }),
        },
        createdAt: Matchers.iso8601DateTime('2022-06-30T16:58:59Z'),
        user: {
          id: Matchers.string('gid://gitlab/User/194645'),
          name: Matchers.string('John Doe'),
          username: Matchers.string('jdoe'),
          webPath: Matchers.term({
            matcher: URL_PATH,
            generate: '/gitlab-bot',
          }),
          webUrl: Matchers.term({
            matcher: URL,
            generate: 'https://gitlab.com/gitlab-bot',
          }),
          email: null,
          avatarUrl: Matchers.term({
            matcher: URL,
            generate:
              'https://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80&d=identicon',
          }),
          status: null,
        },
      },
    },
  },
};

const PipelineHeaderData = {
  body: Matchers.extractPayload(body),

  success: {
    status: 200,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
    body,
  },

  scenario: {
    state: 'a pipeline for a project exists',
    uponReceiving: 'a request for the pipeline header data',
  },

  request: {
    method: 'POST',
    path: '/api/graphql',
  },

  variables: {
    fullPath: 'gitlab-org/gitlab-qa',
    iid: 1,
  },
};

export { PipelineHeaderData };
