import mutations from '~/grafana_integration/store/mutations';
import createState from '~/grafana_integration/store/state';

describe('grafana integration mutations', () => {
  let localState;

  beforeEach(() => {
    localState = createState();
  });

  describe('SET_GRAFANA_URL', () => {
    it('sets grafanaUrl', () => {
      const mockUrl = 'mockUrl';
      mutations.SET_GRAFANA_URL(localState, mockUrl);

      expect(localState.grafanaUrl).toBe(mockUrl);
    });
  });

  describe('SET_GRAFANA_TOKEN', () => {
    it('sets grafanaToken', () => {
      const mockToken = 'mockToken';
      mutations.SET_GRAFANA_TOKEN(localState, mockToken);

      expect(localState.grafanaToken).toBe(mockToken);
    });
  });
  describe('SET_GRAFANA_ENABLED', () => {
    it('updates grafanaEnabled for integration', () => {
      mutations.SET_GRAFANA_ENABLED(localState, true);

      expect(localState.grafanaEnabled).toBe(true);
    });
  });
});
