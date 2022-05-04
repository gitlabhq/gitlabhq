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

  describe('SET_SUBSCRIPTIONS_LOADING', () => {
    it('sets subscriptions loading flag', () => {
      mutations.SET_SUBSCRIPTIONS_LOADING(localState, true);

      expect(localState.subscriptionsLoading).toBe(true);
    });
  });

  describe('SET_SUBSCRIPTIONS', () => {
    it('sets subscriptions loading flag', () => {
      const mockSubscriptions = [{ name: 'test' }];
      mutations.SET_SUBSCRIPTIONS(localState, mockSubscriptions);

      expect(localState.subscriptions).toBe(mockSubscriptions);
    });
  });
});
