import getters from '~/boards/stores/getters';
import { inactiveId } from '~/boards/constants';
import {
  mockIssue,
  mockIssue2,
  mockIssues,
  mockIssuesByListId,
  issues,
  mockLists,
} from '../mock_data';

describe('Boards - Getters', () => {
  describe('isSidebarOpen', () => {
    it('returns true when activeId is not equal to 0', () => {
      const state = {
        activeId: 1,
      };

      expect(getters.isSidebarOpen(state)).toBe(true);
    });

    it('returns false when activeId is equal to 0', () => {
      const state = {
        activeId: inactiveId,
      };

      expect(getters.isSidebarOpen(state)).toBe(false);
    });
  });

  describe('isSwimlanesOn', () => {
    afterEach(() => {
      window.gon = { features: {} };
    });

    it('returns false', () => {
      expect(getters.isSwimlanesOn()).toBe(false);
    });
  });

  describe('getIssueById', () => {
    const state = { issues: { 1: 'issue' } };

    it.each`
      id     | expected
      ${'1'} | ${'issue'}
      ${''}  | ${{}}
    `('returns $expected when $id is passed to state', ({ id, expected }) => {
      expect(getters.getIssueById(state)(id)).toEqual(expected);
    });
  });

  describe('activeIssue', () => {
    it.each`
      id     | expected
      ${'1'} | ${'issue'}
      ${''}  | ${{}}
    `('returns $expected when $id is passed to state', ({ id, expected }) => {
      const state = { issues: { 1: 'issue' }, activeId: id };

      expect(getters.activeIssue(state)).toEqual(expected);
    });
  });

  describe('groupPathByIssueId', () => {
    it('returns group path for the active issue', () => {
      const mockActiveIssue = {
        referencePath: 'gitlab-org/gitlab-test#1',
      };
      expect(getters.groupPathForActiveIssue({}, { activeIssue: mockActiveIssue })).toEqual(
        'gitlab-org',
      );
    });

    it('returns empty string as group path when active issue is an empty object', () => {
      const mockActiveIssue = {};
      expect(getters.groupPathForActiveIssue({}, { activeIssue: mockActiveIssue })).toEqual('');
    });
  });

  describe('projectPathByIssueId', () => {
    it('returns project path for the active issue', () => {
      const mockActiveIssue = {
        referencePath: 'gitlab-org/gitlab-test#1',
      };
      expect(getters.projectPathForActiveIssue({}, { activeIssue: mockActiveIssue })).toEqual(
        'gitlab-org/gitlab-test',
      );
    });

    it('returns empty string as project path when active issue is an empty object', () => {
      const mockActiveIssue = {};
      expect(getters.projectPathForActiveIssue({}, { activeIssue: mockActiveIssue })).toEqual('');
    });
  });

  describe('getIssuesByList', () => {
    const boardsState = {
      issuesByListId: mockIssuesByListId,
      issues,
    };
    it('returns issues for a given listId', () => {
      const getIssueById = (issueId) => [mockIssue, mockIssue2].find(({ id }) => id === issueId);

      expect(getters.getIssuesByList(boardsState, { getIssueById })('gid://gitlab/List/2')).toEqual(
        mockIssues,
      );
    });
  });

  const boardsState = {
    boardLists: {
      'gid://gitlab/List/1': mockLists[0],
      'gid://gitlab/List/2': mockLists[1],
    },
  };

  describe('getListByLabelId', () => {
    it('returns list for a given label id', () => {
      expect(getters.getListByLabelId(boardsState)('gid://gitlab/GroupLabel/121')).toEqual(
        mockLists[1],
      );
    });
  });

  describe('getListByTitle', () => {
    it('returns list for a given list title', () => {
      expect(getters.getListByTitle(boardsState)('To Do')).toEqual(mockLists[1]);
    });
  });
});
