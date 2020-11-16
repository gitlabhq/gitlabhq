import testAction from 'helpers/vuex_action_helper';
import createState from '~/integrations/edit/store/state';
import {
  setOverride,
  setIsSaving,
  setIsTesting,
  setIsResetting,
} from '~/integrations/edit/store/actions';
import * as types from '~/integrations/edit/store/mutation_types';

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
});
