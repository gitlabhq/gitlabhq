import { Matchers } from '@pact-foundation/pact';
import { REDIRECT_HTML } from '../../../helpers/common_regex_patterns';

const body = Matchers.term({
  matcher: REDIRECT_HTML,
  generate:
    '<html><body>You are being <a href="http://example.org/gitlab-org/gitlab-qa/-/pipelines/5">redirected</a>.</body></html>',
});

const NewProjectPipeline = {
  success: {
    status: 302,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
    },
    body,
  },

  scenario: {
    state: 'a project with a valid .gitlab-ci.yml configuration exists',
    uponReceiving: 'a request to create a new pipeline',
  },

  request: {
    withRequest: {
      method: 'POST',
      path: '/gitlab-org/gitlab-qa/-/pipelines',
      headers: {
        Accept: '*/*',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: {
        ref: 'master',
      },
    },
  },
};

export { NewProjectPipeline };
