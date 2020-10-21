import testAction from 'helpers/vuex_action_helper';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import actions from '~/whats_new/store/actions';
import * as types from '~/whats_new/store/mutation_types';
import axios from '~/lib/utils/axios_utils';

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

  describe('fetchItems', () => {
    let axiosMock;

    beforeEach(async () => {
      axiosMock = new MockAdapter(axios);
      axiosMock
        .onGet('/-/whats_new')
        .replyOnce(200, [{ title: 'Whats New Drawer', url: 'www.url.com' }]);

      await waitForPromises();
    });

    afterEach(() => {
      axiosMock.restore();
    });

    it('should commit setFeatures', () => {
      testAction(actions.fetchItems, {}, {}, [
        { type: types.SET_FEATURES, payload: [{ title: 'Whats New Drawer', url: 'www.url.com' }] },
      ]);
    });
  });
});
