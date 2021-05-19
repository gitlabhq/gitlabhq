import { getAlert } from '~/ide/lib/alerts';
import EnvironmentsMessage from '~/ide/lib/alerts/environments.vue';
import { createStore } from '~/ide/stores';
import * as getters from '~/ide/stores/getters/alert';
import { file } from '../../helpers';

describe('IDE store alert getters', () => {
  let localState;
  let localStore;

  beforeEach(() => {
    localStore = createStore();
    localState = localStore.state;
  });

  describe('alerts', () => {
    describe('shows an alert about environments', () => {
      let alert;

      beforeEach(() => {
        const f = file('.gitlab-ci.yml');
        localState.openFiles.push(f);
        localState.currentActivityView = 'repo-commit-section';
        localState.environmentsGuidanceAlertDetected = true;
        localState.environmentsGuidanceAlertDismissed = false;

        const alertKey = getters.getAlert(localState)(f);
        alert = getAlert(alertKey);
      });

      it('has a message suggesting to use environments', () => {
        expect(alert.message).toEqual(EnvironmentsMessage);
      });

      it('dispatches to dismiss the callout on dismiss', () => {
        jest.spyOn(localStore, 'dispatch').mockImplementation();
        alert.dismiss(localStore);
        expect(localStore.dispatch).toHaveBeenCalledWith('dismissEnvironmentsGuidance');
      });

      it('should be a tip alert', () => {
        expect(alert.props).toEqual({ variant: 'tip' });
      });
    });
  });
});
