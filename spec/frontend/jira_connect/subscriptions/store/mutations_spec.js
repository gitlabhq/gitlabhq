import mutations from '~/jira_connect/subscriptions/store/mutations';
import state from '~/jira_connect/subscriptions/store/state';

describe('JiraConnect store mutations', () => {
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('SET_ALERT', () => {
    it('sets alert state', () => {
      mutations.SET_ALERT(localState, {
        message: 'test error',
        variant: 'danger',
        title: 'test title',
        linkUrl: 'linkUrl',
      });

      expect(localState.alert).toMatchObject({
        message: 'test error',
        variant: 'danger',
        title: 'test title',
        linkUrl: 'linkUrl',
      });
    });
  });
});
