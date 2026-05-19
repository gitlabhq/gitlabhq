import { uniq } from 'lodash-es';
import { createTestingPinia } from '@pinia/testing';
import { userList } from 'jest/feature_flags/mock_data';
import Api from '~/api';
import { states } from '~/user_lists/constants/show';
import { useUserListShow } from '~/user_lists/store/show';
import { parseUserIds, stringifyUserIds } from '~/user_lists/store/utils';

jest.mock('~/api');

describe('User Lists Show Store', () => {
  let store;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useUserListShow();
    store.projectId = '1';
    store.userListIid = '2';
  });

  describe('fetchUserList', () => {
    it('sets loading state', () => {
      Api.fetchFeatureFlagUserList.mockReturnValue(new Promise(() => {}));

      store.fetchUserList();

      expect(store.state).toBe(states.LOADING);
    });

    it('sets user list on success', async () => {
      Api.fetchFeatureFlagUserList.mockResolvedValue({ data: userList });

      await store.fetchUserList();

      expect(Api.fetchFeatureFlagUserList).toHaveBeenCalledWith('1', '2');
      expect(store.state).toBe(states.SUCCESS);
      expect(store.userList).toEqual(userList);
      expect(store.userIds).toEqual(userList.user_xids.split(','));
    });

    it('sets empty userIds when user_xids is empty', async () => {
      Api.fetchFeatureFlagUserList.mockResolvedValue({
        data: { ...userList, user_xids: '' },
      });

      await store.fetchUserList();

      expect(store.userIds).toEqual([]);
    });

    it('sets error state on failure and leaves user list data unchanged', async () => {
      Api.fetchFeatureFlagUserList.mockRejectedValue({ message: 'fail' });

      await store.fetchUserList();

      expect(store.state).toBe(states.ERROR);
      expect(store.userList).toBeNull();
      expect(store.userIds).toEqual([]);
    });
  });

  describe('dismissErrorAlert', () => {
    it('sets state to ERROR_DISMISSED', () => {
      store.dismissErrorAlert();

      expect(store.state).toBe(states.ERROR_DISMISSED);
    });
  });

  describe('addUserIds', () => {
    const newIds = ['user3', 'test1', '1', '3', ''];

    beforeEach(() => {
      store.state = states.SUCCESS;
      store.userIds = parseUserIds(userList.user_xids);
      store.userList = userList;
      Api.updateFeatureFlagUserList.mockResolvedValue({ data: userList });
    });

    it('adds new IDs to the state unless empty', () => {
      store.addUserIds(newIds.join(', '));

      newIds.filter((id) => id).forEach((id) => expect(store.userIds).toContain(id));
    });

    it('does not add duplicate IDs', () => {
      store.addUserIds(newIds.join(', '));

      expect(store.userIds).toEqual(uniq(store.userIds));
    });

    it('calls updateUserList', async () => {
      await store.addUserIds('newuser');

      expect(Api.updateFeatureFlagUserList).toHaveBeenCalledWith('1', {
        ...userList,
        user_xids: stringifyUserIds([...parseUserIds(userList.user_xids), 'newuser']),
      });
    });
  });

  describe('removeUserId', () => {
    let originalUserIds;

    beforeEach(() => {
      store.state = states.SUCCESS;
      store.userIds = parseUserIds(userList.user_xids);
      store.userList = userList;
      originalUserIds = [...store.userIds];
      Api.updateFeatureFlagUserList.mockResolvedValue({ data: userList });
    });

    it('removes the given ID', () => {
      const removedId = originalUserIds[0];
      store.removeUserId(removedId);

      expect(store.userIds).not.toContain(removedId);
    });

    it('leaves the rest of the IDs', () => {
      const removedId = originalUserIds[0];
      store.removeUserId(removedId);

      originalUserIds
        .filter((id) => id !== removedId)
        .forEach((id) => expect(store.userIds).toContain(id));
    });

    it('calls updateUserList', async () => {
      await store.removeUserId(originalUserIds[0]);

      expect(Api.updateFeatureFlagUserList).toHaveBeenCalled();
    });
  });

  describe('updateUserList', () => {
    beforeEach(() => {
      store.userList = userList;
      store.userIds = ['user1', 'user2', 'user3'];
    });

    it('sets loading state', () => {
      Api.updateFeatureFlagUserList.mockReturnValue(new Promise(() => {}));

      store.updateUserList();

      expect(store.state).toBe(states.LOADING);
    });

    it('updates the user list on success', async () => {
      Api.updateFeatureFlagUserList.mockResolvedValue({ data: userList });

      await store.updateUserList();

      expect(Api.updateFeatureFlagUserList).toHaveBeenCalledWith('1', {
        ...userList,
        user_xids: stringifyUserIds(['user1', 'user2', 'user3']),
      });
      expect(store.state).toBe(states.SUCCESS);
      expect(store.userList).toEqual(userList);
      expect(store.userIds).toEqual(userList.user_xids.split(','));
    });

    it('sets error state on failure and leaves user list data unchanged', async () => {
      Api.updateFeatureFlagUserList.mockRejectedValue({ message: 'fail' });

      await store.updateUserList();

      expect(store.state).toBe(states.ERROR);
      expect(store.userList).toEqual(userList);
      expect(store.userIds).toEqual(['user1', 'user2', 'user3']);
    });
  });
});
