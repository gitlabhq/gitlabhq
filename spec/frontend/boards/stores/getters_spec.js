import getters from '~/boards/stores/getters';
import { inactiveId } from '~/boards/constants';
import {
  mockIssue,
  mockIssue2,
  mockIssues,
  mockIssuesByListId,
  issues,
  mockListsWithModel,
} from '../mock_data';

describe('Boards - Getters', () => {
  describe('labelToggleState', () => {
    it('should return "on" when isShowingLabels is true', () => {
      const state = {
        isShowingLabels: true,
      };

      expect(getters.labelToggleState(state)).toBe('on');
    });

    it('should return "off" when isShowingLabels is false', () => {
      const state = {
        isShowingLabels: false,
      };

      expect(getters.labelToggleState(state)).toBe('off');
    });
  });

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
    const state = { issues: { '1': 'issue' } };

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
      const state = { issues: { '1': 'issue' }, activeId: id };

      expect(getters.activeIssue(state)).toEqual(expected);
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

    it('returns empty string as project when active issue is an empty object', () => {
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
      const getIssueById = issueId => [mockIssue, mockIssue2].find(({ id }) => id === issueId);

      expect(getters.getIssuesByList(boardsState, { getIssueById })('gid://gitlab/List/2')).toEqual(
        mockIssues,
      );
    });
  });

  const boardsState = {
    boardLists: {
      'gid://gitlab/List/1': mockListsWithModel[0],
      'gid://gitlab/List/2': mockListsWithModel[1],
    },
  };

  describe('getListByLabelId', () => {
    it('returns list for a given label id', () => {
      expect(getters.getListByLabelId(boardsState)('gid://gitlab/GroupLabel/121')).toEqual(
        mockListsWithModel[1],
      );
    });
  });

  describe('getListByTitle', () => {
    it('returns list for a given list title', () => {
      expect(getters.getListByTitle(boardsState)('To Do')).toEqual(mockListsWithModel[1]);
    });
  });
});
