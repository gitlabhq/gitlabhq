import { Matchers } from '@pact-foundation/pact';
import { REDIRECT_HTML } from '../../../helpers/common_regex_patterns';

const body = Matchers.term({
  matcher: REDIRECT_HTML,
  generate:
    '<html><body>You are being <a href="http://example.org/gitlab-org/gitlab-qa/-/pipelines/5">redirected</a>.</body></html>',
});

const UpdatePipelineSchedule = {
  success: {
    status: 302,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
    },
    body,
  },

  scenario: {
    state: 'a project with a pipeline schedule exists',
    uponReceiving: 'a request to edit a pipeline schedule',
  },

  request: {
    withRequest: {
      method: 'PUT',
      path: '/gitlab-org/gitlab-qa/-/pipeline_schedules/25',
      headers: {
        Accept: '*/*',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: {
        schedule: {
          description: 'bar',
          cron: '0 1 * * *',
          cron_timezone: 'UTC',
          active: true,
        },
      },
    },
  },
};

export { UpdatePipelineSchedule };
