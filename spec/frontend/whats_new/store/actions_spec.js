import testAction from 'helpers/vuex_action_helper';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import actions from '~/whats_new/store/actions';
import * as types from '~/whats_new/store/mutation_types';

describe('whats new actions', () => {
  describe('openDrawer', () => {
    useLocalStorageSpy();

    it('should commit openDrawer', () => {
      testAction(actions.openDrawer, 'storage-key', {}, [{ type: types.OPEN_DRAWER }]);

      expect(window.localStorage.setItem).toHaveBeenCalledWith('storage-key', 'false');
    });
  });

  describe('closeDrawer', () => {
    it('should commit closeDrawer', () => {
      testAction(actions.closeDrawer, {}, {}, [{ type: types.CLOSE_DRAWER }]);
    });
  });
});
