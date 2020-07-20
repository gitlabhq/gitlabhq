import createState from '~/integrations/edit/store/state';
import { setOverride } from '~/integrations/edit/store/actions';
import * as types from '~/integrations/edit/store/mutation_types';

import testAction from 'helpers/vuex_action_helper';

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
});
