import testAction from 'helpers/vuex_action_helper';
import actions from '~/whats_new/store/actions';
import * as types from '~/whats_new/store/mutation_types';

describe('whats new actions', () => {
  describe('openDrawer', () => {
    it('should commit openDrawer', () => {
      testAction(actions.openDrawer, {}, {}, [{ type: types.OPEN_DRAWER }]);
    });
  });

  describe('closeDrawer', () => {
    it('should commit closeDrawer', () => {
      testAction(actions.closeDrawer, {}, {}, [{ type: types.CLOSE_DRAWER }]);
    });
  });
});
