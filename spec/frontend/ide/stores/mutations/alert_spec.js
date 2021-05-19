import * as types from '~/ide/stores/mutation_types';
import mutations from '~/ide/stores/mutations/alert';

describe('~/ide/stores/mutations/alert', () => {
  const state = {};

  describe(types.DETECT_ENVIRONMENTS_GUIDANCE_ALERT, () => {
    it('checks the stages for any that configure environments', () => {
      mutations[types.DETECT_ENVIRONMENTS_GUIDANCE_ALERT](state, {
        nodes: [{ groups: { nodes: [{ jobs: { nodes: [{}] } }] } }],
      });
      expect(state.environmentsGuidanceAlertDetected).toBe(true);
      mutations[types.DETECT_ENVIRONMENTS_GUIDANCE_ALERT](state, {
        nodes: [{ groups: { nodes: [{ jobs: { nodes: [{ environment: {} }] } }] } }],
      });
      expect(state.environmentsGuidanceAlertDetected).toBe(false);
    });
  });

  describe(types.DISMISS_ENVIRONMENTS_GUIDANCE_ALERT, () => {
    it('stops environments guidance', () => {
      mutations[types.DISMISS_ENVIRONMENTS_GUIDANCE_ALERT](state);
      expect(state.environmentsGuidanceAlertDismissed).toBe(true);
    });
  });
});
