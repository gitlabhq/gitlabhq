import { initJiraConnect } from '~/jira_connect/subscriptions';
import { getGitlabSignInURL } from '~/jira_connect/subscriptions/utils';

jest.mock('~/jira_connect/subscriptions/utils');

describe('initJiraConnect', () => {
  const mockInitialHref = 'https://gitlab.com';

  beforeEach(() => {
    setFixtures(`
      <a class="js-jira-connect-sign-in" href="${mockInitialHref}">Sign In</a>
      <a class="js-jira-connect-sign-in" href="${mockInitialHref}">Another Sign In</a>
    `);
  });

  const assertSignInLinks = (expectedLink) => {
    Array.from(document.querySelectorAll('.js-jira-connect-sign-in')).forEach((el) => {
      expect(el.getAttribute('href')).toBe(expectedLink);
    });
  };

  describe('Sign in links', () => {
    it('are updated on initialization', async () => {
      const mockSignInLink = `https://gitlab.com?return_to=${encodeURIComponent('/test/location')}`;
      getGitlabSignInURL.mockResolvedValue(mockSignInLink);

      // assert the initial state
      assertSignInLinks(mockInitialHref);

      await initJiraConnect();

      // assert the update has occurred
      assertSignInLinks(mockSignInLink);
    });
  });
});
