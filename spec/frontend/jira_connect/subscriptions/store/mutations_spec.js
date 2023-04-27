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

  describe('SET_SUBSCRIPTIONS', () => {
    it('sets subscriptions loading flag', () => {
      const mockSubscriptions = [{ name: 'test' }];
      mutations.SET_SUBSCRIPTIONS(localState, mockSubscriptions);

      expect(localState.subscriptions).toBe(mockSubscriptions);
    });
  });

  describe('SET_SUBSCRIPTIONS_LOADING', () => {
    it('sets subscriptions loading flag', () => {
      mutations.SET_SUBSCRIPTIONS_LOADING(localState, true);

      expect(localState.subscriptionsLoading).toBe(true);
    });
  });

  describe('SET_SUBSCRIPTIONS_ERROR', () => {
    it('sets subscriptions error', () => {
      mutations.SET_SUBSCRIPTIONS_ERROR(localState, true);

      expect(localState.subscriptionsError).toBe(true);
    });
  });

  describe('SET_CURRENT_USER', () => {
    it('sets currentUser', () => {
      const mockUser = { name: 'root' };
      mutations.SET_CURRENT_USER(localState, mockUser);

      expect(localState.currentUser).toBe(mockUser);
    });
  });

  describe('SET_CURRENT_USER_ERROR', () => {
    it('sets currentUserError', () => {
      mutations.SET_CURRENT_USER_ERROR(localState, true);

      expect(localState.currentUserError).toBe(true);
    });
  });

  describe('SET_ACCESS_TOKEN', () => {
    it('sets accessToken', () => {
      const mockAccessToken = 'asdf1234';
      mutations.SET_ACCESS_TOKEN(localState, mockAccessToken);

      expect(localState.accessToken).toBe(mockAccessToken);
    });
  });
});
