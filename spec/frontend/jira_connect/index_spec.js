import { initJiraConnect } from '~/jira_connect';

jest.mock('~/jira_connect/utils', () => ({
  getLocation: jest.fn().mockResolvedValue('test/location'),
}));

describe('initJiraConnect', () => {
  beforeEach(async () => {
    setFixtures(`
      <a class="js-jira-connect-sign-in" href="https://gitlab.com">Sign In</a>
      <a class="js-jira-connect-sign-in" href="https://gitlab.com">Another Sign In</a>
    `);

    await initJiraConnect();
  });

  describe('Sign in links', () => {
    it('have `return_to` query parameter', () => {
      Array.from(document.querySelectorAll('.js-jira-connect-sign-in')).forEach((el) => {
        expect(el.href).toContain('return_to=test/location');
      });
    });
  });
});
