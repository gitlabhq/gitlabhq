import testAction from 'helpers/vuex_action_helper';
import service from '~/ide/services';
import {
  detectEnvironmentsGuidance,
  dismissEnvironmentsGuidance,
} from '~/ide/stores/actions/alert';
import * as types from '~/ide/stores/mutation_types';

jest.mock('~/ide/services');

describe('~/ide/stores/actions/alert', () => {
  describe('detectEnvironmentsGuidance', () => {
    it('should try to fetch CI info', () => {
      const stages = ['a', 'b', 'c'];
      service.getCiConfig.mockResolvedValue({ stages });

      return testAction(
        detectEnvironmentsGuidance,
        'the content',
        { currentProjectId: 'gitlab/test' },
        [{ type: types.DETECT_ENVIRONMENTS_GUIDANCE_ALERT, payload: stages }],
        [],
        () => expect(service.getCiConfig).toHaveBeenCalledWith('gitlab/test', 'the content'),
      );
    });
  });
  describe('dismissCallout', () => {
    it('should try to dismiss the given callout', () => {
      const callout = { featureName: 'test', dismissedAt: 'now' };

      service.dismissUserCallout.mockResolvedValue({ userCalloutCreate: { userCallout: callout } });

      return testAction(
        dismissEnvironmentsGuidance,
        undefined,
        {},
        [{ type: types.DISMISS_ENVIRONMENTS_GUIDANCE_ALERT }],
        [],
        () =>
          expect(service.dismissUserCallout).toHaveBeenCalledWith(
            'web_ide_ci_environments_guidance',
          ),
      );
    });
  });
});
