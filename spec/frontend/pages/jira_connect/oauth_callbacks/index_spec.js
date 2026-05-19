import { OAUTH_CALLBACK_MESSAGE_TYPE } from '~/jira_connect/subscriptions/constants';

describe('initOAuthCallbacks', () => {
  let originalOpener;
  let originalClose;

  beforeEach(() => {
    originalOpener = window.opener;
    originalClose = window.close;
    window.close = jest.fn();
  });

  afterEach(() => {
    window.opener = originalOpener;
    window.close = originalClose;
    jest.resetModules();
  });

  function setQueryString(search) {
    delete window.location;
    window.location = new URL(`https://gitlab.com/-/jira_connect/oauth_callbacks${search}`);
  }

  describe('when window.opener is null', () => {
    const postMessageSpy = jest.fn();

    beforeEach(() => {
      window.opener = null;
      setQueryString('?code=test-code&state=test-state');
    });

    it('does not close the window', async () => {
      await import('~/pages/jira_connect/oauth_callbacks/index');

      expect(window.close).not.toHaveBeenCalled();
    });

    it('does not call postMessage', async () => {
      await import('~/pages/jira_connect/oauth_callbacks/index');

      expect(postMessageSpy).not.toHaveBeenCalled();
    });

    it('shows a fallback message', async () => {
      await import('~/pages/jira_connect/oauth_callbacks/index');

      expect(document.body.textContent).toContain('GitLab for Jira Cloud app');
    });
  });

  describe('when window.opener exists', () => {
    let postMessageSpy;

    beforeEach(() => {
      postMessageSpy = jest.fn();
      window.opener = {
        location: new URL('https://gitlab.com/-/jira_connect'),
        postMessage: postMessageSpy,
      };
    });

    it('posts success message when code and state params are present', async () => {
      setQueryString('?code=test-code&state=test-state');

      await import('~/pages/jira_connect/oauth_callbacks/index');

      expect(postMessageSpy).toHaveBeenCalledWith(
        {
          success: true,
          code: 'test-code',
          state: 'test-state',
          type: OAUTH_CALLBACK_MESSAGE_TYPE,
        },
        'https://gitlab.com/-/jira_connect',
      );
      expect(window.close).toHaveBeenCalled();
    });

    it.each`
      scenario                | search
      ${'no params'}          | ${''}
      ${'only code present'}  | ${'?code=test-code'}
      ${'only state present'} | ${'?state=test-state'}
    `('posts failure message when $scenario', async ({ search }) => {
      setQueryString(search);

      await import('~/pages/jira_connect/oauth_callbacks/index');

      expect(postMessageSpy).toHaveBeenCalledWith(
        {
          success: false,
          type: OAUTH_CALLBACK_MESSAGE_TYPE,
        },
        'https://gitlab.com/-/jira_connect',
      );
      expect(window.close).toHaveBeenCalled();
    });
  });
});
