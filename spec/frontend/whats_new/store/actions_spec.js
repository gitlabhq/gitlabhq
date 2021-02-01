import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
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
        .replyOnce(200, [{ title: 'Whats New Drawer', url: 'www.url.com' }], {
          'x-next-page': '2',
        });

      await waitForPromises();
    });

    afterEach(() => {
      axiosMock.restore();
    });

    it('passes arguments', () => {
      axiosMock.reset();

      axiosMock
        .onGet('/-/whats_new', { params: { page: 8, version: 40 } })
        .replyOnce(200, [{ title: 'GitLab Stories' }]);

      testAction(
        actions.fetchItems,
        { page: 8, version: 40 },
        {},
        expect.arrayContaining([
          { type: types.ADD_FEATURES, payload: [{ title: 'GitLab Stories' }] },
        ]),
      );
    });

    it('if already fetching, does not fetch', () => {
      testAction(actions.fetchItems, {}, { fetching: true }, []);
    });

    it('should commit fetching, setFeatures and setPagination', () => {
      testAction(actions.fetchItems, {}, {}, [
        { type: types.SET_FETCHING, payload: true },
        { type: types.ADD_FEATURES, payload: [{ title: 'Whats New Drawer', url: 'www.url.com' }] },
        { type: types.SET_PAGE_INFO, payload: { nextPage: 2 } },
        { type: types.SET_FETCHING, payload: false },
      ]);
    });
  });

  describe('setDrawerBodyHeight', () => {
    testAction(actions.setDrawerBodyHeight, 42, {}, [
      { type: types.SET_DRAWER_BODY_HEIGHT, payload: 42 },
    ]);
  });
});
