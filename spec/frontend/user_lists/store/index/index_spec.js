import { createTestingPinia } from '@pinia/testing';
import Api from '~/api';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import { useUserLists } from '~/user_lists/store/index';
import { userList } from 'jest/feature_flags/mock_data';

jest.mock('~/api');

describe('~/user_lists/store/index', () => {
  let store;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useUserLists();
    store.$patch({ projectId: '1' });
  });

  describe('setUserListsOptions', () => {
    it('sets the provided options on state', () => {
      store.setUserListsOptions({ page: '1', scope: 'all' });

      expect(store.options).toEqual({ page: '1', scope: 'all' });
    });
  });

  describe('fetchUserLists', () => {
    it('sets isLoading to true while the request is in flight', () => {
      store.$patch({ isLoading: false });
      Api.fetchFeatureFlagUserLists.mockReturnValue(new Promise(() => {}));

      store.fetchUserLists();

      expect(store.isLoading).toBe(true);
    });

    describe('on success', () => {
      const headers = {
        'x-next-page': '2',
        'x-page': '1',
        'X-Per-Page': '2',
        'X-Prev-Page': '',
        'X-TOTAL': '37',
        'X-Total-Pages': '5',
      };

      beforeEach(() => {
        Api.fetchFeatureFlagUserLists.mockResolvedValue({ data: [userList], headers });
      });

      it('stores the returned user lists and resets isLoading', async () => {
        await store.fetchUserLists();

        expect(store.userLists).toEqual([userList]);
        expect(store.isLoading).toBe(false);
      });

      it('stores pagination info derived from response headers', async () => {
        await store.fetchUserLists();

        expect(store.pageInfo).toEqual(parseIntPagination(normalizeHeaders(headers)));
        expect(store.count).toBe(37);
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        Api.fetchFeatureFlagUserLists.mockRejectedValue(new Error('request failed'));
      });

      it('sets hasError and resets isLoading', async () => {
        await store.fetchUserLists();

        expect(store.hasError).toBe(true);
        expect(store.isLoading).toBe(false);
      });
    });
  });

  describe('deleteUserList', () => {
    beforeEach(() => {
      store.$patch({ userLists: [userList] });
    });

    it('optimistically removes the list from state before the request resolves', () => {
      Api.deleteFeatureFlagUserList.mockReturnValue(new Promise(() => {}));

      store.deleteUserList(userList);

      expect(store.userLists).not.toContain(userList);
    });

    describe('on success', () => {
      beforeEach(() => {
        Api.deleteFeatureFlagUserList.mockResolvedValue();
        Api.fetchFeatureFlagUserLists.mockResolvedValue({ data: [], headers: {} });
      });

      it('refreshes the user lists', async () => {
        await store.deleteUserList(userList);

        expect(Api.fetchFeatureFlagUserLists).toHaveBeenCalled();
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        Api.deleteFeatureFlagUserList.mockRejectedValue({
          response: { data: { message: 'some error' } },
        });
      });

      it('re-adds the list and surfaces the error message as an alert', async () => {
        await store.deleteUserList(userList);

        expect(store.userLists).toContainEqual(userList);
        expect(store.alerts).toEqual(['some error']);
      });

      it('resets isLoading and keeps hasError false', async () => {
        await store.deleteUserList(userList);

        expect(store.isLoading).toBe(false);
        expect(store.hasError).toBe(false);
      });
    });
  });

  describe('clearAlert', () => {
    it('removes the alert at the specified index', () => {
      store.$patch({ alerts: ['a server error', 'another error', 'final error'] });

      store.clearAlert(1);

      expect(store.alerts).toEqual(['a server error', 'final error']);
    });

    it('clears a single remaining alert', () => {
      store.$patch({ alerts: ['a server error'] });

      store.clearAlert(0);

      expect(store.alerts).toEqual([]);
    });
  });
});
