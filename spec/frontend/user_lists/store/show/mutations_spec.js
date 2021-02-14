import { uniq } from 'lodash';
import { userList } from 'jest/feature_flags/mock_data';
import { states } from '~/user_lists/constants/show';
import * as types from '~/user_lists/store/show/mutation_types';
import mutations from '~/user_lists/store/show/mutations';
import createState from '~/user_lists/store/show/state';

describe('User Lists Show Mutations', () => {
  let mockState;

  beforeEach(() => {
    mockState = createState({ projectId: '1', userListIid: '2' });
  });

  describe(types.REQUEST_USER_LIST, () => {
    it('puts us in the loading state', () => {
      mutations[types.REQUEST_USER_LIST](mockState);

      expect(mockState.state).toBe(states.LOADING);
    });
  });

  describe(types.RECEIVE_USER_LIST_SUCCESS, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_USER_LIST_SUCCESS](mockState, userList);
    });

    it('sets the state to LOADED', () => {
      expect(mockState.state).toBe(states.SUCCESS);
    });

    it('sets the active user list', () => {
      expect(mockState.userList).toEqual(userList);
    });

    it('splits the user IDs into an Array', () => {
      expect(mockState.userIds).toEqual(userList.user_xids.split(','));
    });

    it('sets user IDs to an empty Array if an empty string is received', () => {
      mutations[types.RECEIVE_USER_LIST_SUCCESS](mockState, { ...userList, user_xids: '' });
      expect(mockState.userIds).toEqual([]);
    });
  });
  describe(types.RECEIVE_USER_LIST_ERROR, () => {
    it('sets the state to error', () => {
      mutations[types.RECEIVE_USER_LIST_ERROR](mockState);
      expect(mockState.state).toBe(states.ERROR);
    });
  });
  describe(types.ADD_USER_IDS, () => {
    const newIds = ['user3', 'test1', '1', '3', ''];

    beforeEach(() => {
      mutations[types.RECEIVE_USER_LIST_SUCCESS](mockState, userList);
      mutations[types.ADD_USER_IDS](mockState, newIds.join(', '));
    });

    it('adds the new IDs to the state unless empty', () => {
      newIds.filter((id) => id).forEach((id) => expect(mockState.userIds).toContain(id));
    });

    it('does not add duplicate IDs to the state', () => {
      expect(mockState.userIds).toEqual(uniq(mockState.userIds));
    });
  });
  describe(types.REMOVE_USER_ID, () => {
    let userIds;
    let removedId;

    beforeEach(() => {
      mutations[types.RECEIVE_USER_LIST_SUCCESS](mockState, userList);
      userIds = mockState.userIds;
      removedId = 'user3';
      mutations[types.REMOVE_USER_ID](mockState, removedId);
    });

    it('should remove the given id', () => {
      expect(mockState).not.toContain(removedId);
    });

    it('should leave the rest of the IDs alone', () => {
      userIds
        .filter((id) => id !== removedId)
        .forEach((id) => expect(mockState.userIds).toContain(id));
    });
  });
});
