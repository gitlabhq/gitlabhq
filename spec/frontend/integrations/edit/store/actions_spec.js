import testAction from 'helpers/vuex_action_helper';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import createState from '~/integrations/edit/store/state';
import {
  setOverride,
  setIsSaving,
  setIsTesting,
  setIsResetting,
  requestResetIntegration,
  receiveResetIntegrationSuccess,
  receiveResetIntegrationError,
} from '~/integrations/edit/store/actions';
import * as types from '~/integrations/edit/store/mutation_types';

jest.mock('~/lib/utils/url_utility');

describe('Integration form store actions', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('setOverride', () => {
    it('should commit override mutation', () => {
      return testAction(setOverride, true, state, [{ type: types.SET_OVERRIDE, payload: true }]);
    });
  });

  describe('setIsSaving', () => {
    it('should commit isSaving mutation', () => {
      return testAction(setIsSaving, true, state, [{ type: types.SET_IS_SAVING, payload: true }]);
    });
  });

  describe('setIsTesting', () => {
    it('should commit isTesting mutation', () => {
      return testAction(setIsTesting, true, state, [{ type: types.SET_IS_TESTING, payload: true }]);
    });
  });

  describe('setIsResetting', () => {
    it('should commit isResetting mutation', () => {
      return testAction(setIsResetting, true, state, [
        { type: types.SET_IS_RESETTING, payload: true },
      ]);
    });
  });

  describe('requestResetIntegration', () => {
    it('should commit REQUEST_RESET_INTEGRATION mutation', () => {
      return testAction(requestResetIntegration, null, state, [
        { type: types.REQUEST_RESET_INTEGRATION },
      ]);
    });
  });

  describe('receiveResetIntegrationSuccess', () => {
    it('should call refreshCurrentPage()', () => {
      return testAction(receiveResetIntegrationSuccess, null, state, [], [], () => {
        expect(refreshCurrentPage).toHaveBeenCalled();
      });
    });
  });

  describe('receiveResetIntegrationError', () => {
    it('should commit RECEIVE_RESET_INTEGRATION_ERROR mutation', () => {
      return testAction(receiveResetIntegrationError, null, state, [
        { type: types.RECEIVE_RESET_INTEGRATION_ERROR },
      ]);
    });
  });
});
