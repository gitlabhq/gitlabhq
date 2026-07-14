import { Matchers } from '@pact-foundation/pact';
import {
  URL,
  URL_PATH,
  PIPELINE_GROUPS,
  PIPELINE_LABELS,
  PIPELINE_SOURCES,
  PIPELINE_STATUSES,
  PIPELINE_TEXTS,
  USER_STATES,
} from '../../../helpers/common_regex_patterns';

const body = {
  pipelines: Matchers.eachLike({
    id: Matchers.integer(564173401),
    iid: Matchers.integer(8197225),
    user: {
      id: Matchers.integer(1781152),
      username: Matchers.string('gitlab-bot'),
      name: Matchers.string('🤖 GitLab Bot 🤖'),
      state: Matchers.term({
        matcher: USER_STATES,
        generate: 'active',
      }),
      avatar_url: Matchers.term({
        matcher: URL,
        generate: 'https://gitlab.com/uploads/-/system/user/avatar/1516152/avatar.png',
      }),
      web_url: Matchers.term({
        matcher: URL,
        generate: 'https://gitlab.com/gitlab-bot',
      }),
      show_status: Matchers.boolean(false),
      path: Matchers.term({
        matcher: URL_PATH,
        generate: '/gitlab-bot',
      }),
    },
    active: Matchers.boolean(true),
    source: Matchers.term({
      matcher: PIPELINE_SOURCES,
      generate: 'schedule',
    }),
    created_at: Matchers.iso8601DateTimeWithMillis('2022-06-11T00:05:21.558Z'),
    updated_at: Matchers.iso8601DateTimeWithMillis('2022-06-11T00:05:34.258Z'),
    path: Matchers.term({
      matcher: URL_PATH,
      generate: '/gitlab-org/gitlab/-/pipelines/561224401',
    }),
    flags: {
      stuck: Matchers.boolean(false),
      auto_devops: Matchers.boolean(false),
      merge_request: Matchers.boolean(false),
      yaml_errors: Matchers.boolean(false),
      retryable: Matchers.boolean(false),
      cancelable: Matchers.boolean(false),
      failure_reason: Matchers.boolean(false),
      detached_merge_request_pipeline: Matchers.boolean(false),
      merge_request_pipeline: Matchers.boolean(false),
      merge_train_pipeline: Matchers.boolean(false),
      latest: Matchers.boolean(true),
    },
    details: {
      status: {
        icon: Matchers.term({
          matcher: PIPELINE_STATUSES,
          generate: 'status_running',
        }),
        text: Matchers.term({
          matcher: PIPELINE_TEXTS,
          generate: 'Running',
        }),
        label: Matchers.term({
          matcher: PIPELINE_LABELS,
          generate: 'running',
        }),
        group: Matchers.term({
          matcher: PIPELINE_GROUPS,
          generate: 'running',
        }),
        tooltip: Matchers.term({
          matcher: PIPELINE_LABELS,
          generate: 'passed',
        }),
        has_details: Matchers.boolean(true),
        details_path: Matchers.term({
          matcher: URL_PATH,
          generate: '/gitlab-org/gitlab/-/pipelines/566374401',
        }),
        illustration: null,
        favicon: Matchers.term({
          matcher: URL_PATH,
          generate: '/assets/ci_favicons/favicon_status_running.png',
        }),
      },
      stages: Matchers.eachLike({
        name: Matchers.string('sync'),
        title: Matchers.string('sync: passed'),
        status: {
          icon: Matchers.term({
            matcher: PIPELINE_STATUSES,
            generate: 'status_success',
          }),
          text: Matchers.term({
            matcher: PIPELINE_TEXTS,
            generate: 'Passed',
          }),
          label: Matchers.term({
            matcher: PIPELINE_LABELS,
            generate: 'passed',
          }),
          group: Matchers.term({
            matcher: PIPELINE_GROUPS,
            generate: 'success',
          }),
          tooltip: Matchers.term({
            matcher: PIPELINE_LABELS,
            generate: 'passed',
          }),
          has_details: Matchers.boolean(true),
          details_path: Matchers.term({
            matcher: URL_PATH,
            generate: '/gitlab-org/gitlab/-/pipelines/561174401#sync',
          }),
          illustration: null,
          favicon: Matchers.term({
            matcher: URL_PATH,
            generate: '/assets/ci_favicons/favicon_status_success.png',
          }),
        },
        path: Matchers.term({
          matcher: URL_PATH,
          generate: '/gitlab-org/gitlab/-/pipelines/561124401#sync',
        }),
        dropdown_path: Matchers.term({
          matcher: URL_PATH,
          generate: '/gitlab-org/gitlab/-/pipelines/561174401/stage.json?stage=sync',
        }),
      }),
      duration: Matchers.integer(25),
      finished_at: Matchers.iso8601DateTimeWithMillis('2022-06-11T00:55:21.558Z'),
      name: Matchers.string('Pipeline'),
      manual_actions: Matchers.eachLike({
        name: Matchers.string('review-docs-deploy'),
        playable: Matchers.boolean(true),
        scheduled: Matchers.boolean(false),
      }),
      scheduled_actions: Matchers.eachLike({
        name: Matchers.string('review-docs-schedule'),
        playable: Matchers.boolean(true),
        scheduled: Matchers.boolean(false),
      }),
    },
    ref: {
      name: Matchers.string('master'),
      path: Matchers.term({
        matcher: URL_PATH,
        generate: '/gitlab-org/gitlab/-/commits/master',
      }),
      tag: Matchers.boolean(false),
      branch: Matchers.boolean(true),
      merge_request: Matchers.boolean(false),
    },
    commit: {
      id: Matchers.string('e6d797385144b955c6d4ecfa00e9656dc33efd2b'),
      short_id: Matchers.string('e6d79738'),
      created_at: Matchers.iso8601DateTimeWithMillis('2022-06-10T22:02:10.000+00:00'),
      parent_ids: Matchers.eachLike(Matchers.string('3b0e053a24958174eaa7e3b183c7263432890d1c')),
      title: Matchers.string("Merge branch 'ee-test' into 'master'"),
      message: Matchers.string("Merge branch 'ee-test' into 'master'\nThis is a test."),
      author_name: Matchers.string('John Doe'),
      author_email: Matchers.email('jdoe@gitlab.com'),
      authored_date: Matchers.iso8601DateTimeWithMillis('2022-06-10T22:02:10.000+00:00'),
      committer_name: Matchers.string('John Doe'),
      committer_email: Matchers.email('jdoe@gitlab.com'),
      committed_date: Matchers.iso8601DateTimeWithMillis('2022-06-10T22:02:10.000+00:00'),
      trailers: {},
      web_url: Matchers.term({
        matcher: URL,
        generate: 'https://gitlab.com/gitlab-org/gitlab/-/commit/f559253c514d9ab707c66e',
      }),
      author: null,
      author_gravatar_url: Matchers.term({
        matcher: URL,
        generate:
          'https://secure.gravatar.com/avatar/d85e45af29611ac2c1395e3c3d6ec5d6?s=80\u0026d=identicon',
      }),
      commit_url: Matchers.term({
        matcher: URL,
        generate:
          'https://gitlab.com/gitlab-org/gitlab/-/commit/dc7522f559253c514d9ab707c66e7a1026abca5a',
      }),
      commit_path: Matchers.term({
        matcher: URL_PATH,
        generate: '/gitlab-org/gitlab/-/commit/dc7522f559253c514d9ab707c66e7a1026abca5a',
      }),
    },
    project: {
      id: Matchers.integer(253964),
      name: Matchers.string('GitLab'),
      full_path: Matchers.term({
        matcher: URL_PATH,
        generate: '/gitlab-org/gitlab',
      }),
      full_name: Matchers.string('GitLab.org / GitLab'),
    },
    triggered_by: null,
    triggered: [],
  }),
  count: {
    all: Matchers.string('1,000+'),
  },
};

const ProjectPipelines = {
  body: Matchers.extractPayload(body),

  success: {
    status: 200,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
    body,
  },

  scenario: {
    state: 'a few pipelines for a project exists',
    uponReceiving: 'a request for a list of project pipelines',
  },

  request: {
    withRequest: {
      method: 'GET',
      path: '/gitlab-org/gitlab-qa/-/pipelines.json',
      headers: {
        Accept: '*/*',
      },
      query: 'scope=all&page=1',
    },
  },
};

export { ProjectPipelines };
