import mutations from '~/self_monitor/store/mutations';
import createState from '~/self_monitor/store/state';

describe('self monitoring mutations', () => {
  let localState;

  beforeEach(() => {
    localState = createState();
  });

  describe('SET_ENABLED', () => {
    it('sets selfMonitor', () => {
      mutations.SET_ENABLED(localState, true);

      expect(localState.projectEnabled).toBe(true);
    });
  });

  describe('SET_PROJECT_CREATED', () => {
    it('sets projectCreated', () => {
      mutations.SET_PROJECT_CREATED(localState, true);

      expect(localState.projectCreated).toBe(true);
    });
  });

  describe('SET_SHOW_ALERT', () => {
    it('sets showAlert', () => {
      mutations.SET_SHOW_ALERT(localState, true);

      expect(localState.showAlert).toBe(true);
    });
  });

  describe('SET_PROJECT_URL', () => {
    it('sets projectPath', () => {
      mutations.SET_PROJECT_URL(localState, '/url/');

      expect(localState.projectPath).toBe('/url/');
    });
  });

  describe('SET_LOADING', () => {
    it('sets loading', () => {
      mutations.SET_LOADING(localState, true);

      expect(localState.loading).toBe(true);
    });
  });

  describe('SET_ALERT_CONTENT', () => {
    it('set alertContent', () => {
      const alertContent = {
        message: 'success',
        actionText: 'undo',
        actionName: 'createProject',
      };

      mutations.SET_ALERT_CONTENT(localState, alertContent);

      expect(localState.alertContent).toBe(alertContent);
    });
  });
});
