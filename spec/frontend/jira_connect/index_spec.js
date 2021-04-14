import waitForPromises from 'helpers/wait_for_promises';
import { initJiraConnect } from '~/jira_connect';
import { removeSubscription } from '~/jira_connect/api';

jest.mock('~/jira_connect/api', () => ({
  removeSubscription: jest.fn().mockResolvedValue(),
}));

jest.mock('~/jira_connect/utils', () => ({
  getLocation: jest.fn().mockResolvedValue('test/location'),
}));

describe('initJiraConnect', () => {
  beforeEach(async () => {
    setFixtures(`
      <a class="js-jira-connect-sign-in" href="https://gitlab.com">Sign In</a>
      <a class="js-jira-connect-sign-in" href="https://gitlab.com">Another Sign In</a>

      <a href="https://gitlab.com/sub1" class="js-jira-connect-remove-subscription">Remove</a>
      <a href="https://gitlab.com/sub2" class="js-jira-connect-remove-subscription">Remove</a>
      <a href="https://gitlab.com/sub3" class="js-jira-connect-remove-subscription">Remove</a>
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

  describe('`remove subscription` buttons', () => {
    describe('on click', () => {
      it('calls `removeSubscription`', () => {
        Array.from(document.querySelectorAll('.js-jira-connect-remove-subscription')).forEach(
          (removeSubscriptionButton) => {
            removeSubscriptionButton.dispatchEvent(new Event('click'));

            waitForPromises();

            expect(removeSubscription).toHaveBeenCalledWith(removeSubscriptionButton.href);
            expect(removeSubscription).toHaveBeenCalledTimes(1);

            removeSubscription.mockClear();
          },
        );
      });
    });
  });
});
