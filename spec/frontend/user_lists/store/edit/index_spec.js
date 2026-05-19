import { createTestingPinia } from '@pinia/testing';
import Api from '~/api';
import { visitUrl } from '~/lib/utils/url_utility';
import statuses from '~/user_lists/constants/edit';
import { useEditUserList } from '~/user_lists/store/edit';
import { userList } from 'jest/feature_flags/mock_data';

jest.mock('~/api');
jest.mock('~/lib/utils/url_utility');

describe('~/user_lists/store/edit', () => {
  let store;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useEditUserList();
    store.$patch({ projectId: '1', userListIid: '2' });
  });

  describe('fetchUserList', () => {
    it('sets status to LOADING while the request is in flight', () => {
      store.$patch({ status: statuses.UNSYNCED });
      Api.fetchFeatureFlagUserList.mockReturnValue(new Promise(() => {}));

      store.fetchUserList();

      expect(store.status).toBe(statuses.LOADING);
    });

    describe('on success', () => {
      beforeEach(() => {
        Api.fetchFeatureFlagUserList.mockResolvedValue({ data: userList });
      });

      it('calls the API with projectId and userListIid', async () => {
        await store.fetchUserList();

        expect(Api.fetchFeatureFlagUserList).toHaveBeenCalledWith('1', '2');
      });

      it('sets status to SUCCESS and stores the user list', async () => {
        await store.fetchUserList();

        expect(store.status).toBe(statuses.SUCCESS);
        expect(store.userList).toEqual(userList);
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        Api.fetchFeatureFlagUserList.mockRejectedValue({
          response: { data: { message: ['error'] } },
        });
      });

      it('calls the API with projectId and userListIid', async () => {
        await store.fetchUserList();

        expect(Api.fetchFeatureFlagUserList).toHaveBeenCalledWith('1', '2');
      });

      it('sets status to ERROR and stores the error message', async () => {
        await store.fetchUserList();

        expect(store.status).toBe(statuses.ERROR);
        expect(store.errorMessage).toEqual(['error']);
      });
    });
  });

  describe('dismissErrorAlert', () => {
    it('sets status to UNSYNCED', () => {
      store.dismissErrorAlert();

      expect(store.status).toBe(statuses.UNSYNCED);
    });
  });

  describe('updateUserList', () => {
    const updatedList = { ...userList, name: 'new' };

    describe('on success', () => {
      beforeEach(() => {
        Api.updateFeatureFlagUserList.mockResolvedValue({ data: userList });
      });

      it('calls the API with projectId and the updated list payload', async () => {
        await store.updateUserList(updatedList);

        expect(Api.updateFeatureFlagUserList).toHaveBeenCalledWith('1', {
          name: updatedList.name,
          iid: updatedList.iid,
        });
      });

      it('redirects to the user list path', async () => {
        await store.updateUserList(updatedList);

        expect(visitUrl).toHaveBeenCalledWith(userList.path);
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        Api.updateFeatureFlagUserList.mockRejectedValue({ message: 'error' });
      });

      it('calls the API with projectId and the updated list payload', async () => {
        await store.updateUserList(updatedList);

        expect(Api.updateFeatureFlagUserList).toHaveBeenCalledWith('1', {
          name: updatedList.name,
          iid: updatedList.iid,
        });
      });

      it('sets status to ERROR and stores the error message', async () => {
        await store.updateUserList(updatedList);

        expect(store.status).toBe(statuses.ERROR);
        expect(store.errorMessage).toEqual(['error']);
      });
    });
  });
});
