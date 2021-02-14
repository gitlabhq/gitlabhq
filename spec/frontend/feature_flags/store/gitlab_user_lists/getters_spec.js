import {
  userListOptions,
  hasUserLists,
  isLoading,
  hasError,
} from '~/feature_flags/store/gitlab_user_list/getters';
import createState from '~/feature_flags/store/gitlab_user_list/state';
import statuses from '~/feature_flags/store/gitlab_user_list/status';
import { userList } from '../../mock_data';

describe('~/feature_flags/store/gitlab_user_list/getters', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = createState({ projectId: '8' });
    mockedState.userLists = [userList];
  });

  describe('userListOption', () => {
    it('should return user lists in a way usable by a dropdown', () => {
      expect(userListOptions(mockedState)).toEqual([{ value: userList.id, text: userList.name }]);
    });

    it('should return an empty array if there are no lists', () => {
      mockedState.userLists = [];
      expect(userListOptions(mockedState)).toEqual([]);
    });
  });

  describe('hasUserLists', () => {
    it.each`
      userLists     | status            | result
      ${[userList]} | ${statuses.IDLE}  | ${true}
      ${[]}         | ${statuses.IDLE}  | ${false}
      ${[]}         | ${statuses.START} | ${true}
    `(
      'should return $result if there are $userLists.length user lists and the status is $status',
      ({ userLists, status, result }) => {
        mockedState.userLists = userLists;
        mockedState.status = status;
        expect(hasUserLists(mockedState)).toBe(result);
      },
    );
  });

  describe('isLoading', () => {
    it.each`
      status              | result
      ${statuses.LOADING} | ${true}
      ${statuses.ERROR}   | ${false}
      ${statuses.IDLE}    | ${false}
    `('should return $result if the status is "$status"', ({ status, result }) => {
      mockedState.status = status;
      expect(isLoading(mockedState)).toBe(result);
    });
  });

  describe('hasError', () => {
    it.each`
      status              | result
      ${statuses.LOADING} | ${false}
      ${statuses.ERROR}   | ${true}
      ${statuses.IDLE}    | ${false}
    `('should return $result if the status is "$status"', ({ status, result }) => {
      mockedState.status = status;
      expect(hasError(mockedState)).toBe(result);
    });
  });
});
