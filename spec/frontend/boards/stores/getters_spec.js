import { inactiveId } from '~/boards/constants';
import getters from '~/boards/stores/getters';
import {
  mockIssue,
  mockIssue2,
  mockIssues,
  mockIssuesByListId,
  issues,
  mockLists,
  mockGroupProject1,
  mockArchivedGroupProject,
} from '../mock_data';

describe('Boards - Getters', () => {
  describe('isGroupBoard', () => {
    it('returns true when boardType on state is group', () => {
      const state = {
        boardType: 'group',
      };

      expect(getters.isGroupBoard(state)).toBe(true);
    });

    it('returns false when boardType on state is not group', () => {
      const state = {
        boardType: 'project',
      };

      expect(getters.isGroupBoard(state)).toBe(false);
    });
  });

  describe('isProjectBoard', () => {
    it('returns true when boardType on state is project', () => {
      const state = {
        boardType: 'project',
      };

      expect(getters.isProjectBoard(state)).toBe(true);
    });

    it('returns false when boardType on state is not project', () => {
      const state = {
        boardType: 'group',
      };

      expect(getters.isProjectBoard(state)).toBe(false);
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

  describe('getBoardItemById', () => {
    const state = { boardItems: { 1: 'issue' } };

    it.each`
      id     | expected
      ${'1'} | ${'issue'}
      ${''}  | ${{}}
    `('returns $expected when $id is passed to state', ({ id, expected }) => {
      expect(getters.getBoardItemById(state)(id)).toEqual(expected);
    });
  });

  describe('activeBoardItem', () => {
    it.each`
      id     | expected
      ${'1'} | ${'issue'}
      ${''}  | ${{ id: '', iid: '', fullId: '' }}
    `('returns $expected when $id is passed to state', ({ id, expected }) => {
      const state = { boardItems: { 1: 'issue' }, activeId: id };

      expect(getters.activeBoardItem(state)).toEqual(expected);
    });
  });

  describe('groupPathByIssueId', () => {
    it('returns group path for the active issue', () => {
      const mockActiveIssue = {
        referencePath: 'gitlab-org/gitlab-test#1',
      };
      expect(getters.groupPathForActiveIssue({}, { activeBoardItem: mockActiveIssue })).toEqual(
        'gitlab-org',
      );
    });

    it('returns group path of last subgroup for the active issue', () => {
      const mockActiveIssue = {
        referencePath: 'gitlab-org/subgroup/subsubgroup/gitlab-test#1',
      };
      expect(getters.groupPathForActiveIssue({}, { activeBoardItem: mockActiveIssue })).toEqual(
        'gitlab-org/subgroup/subsubgroup',
      );
    });

    it('returns empty string as group path when active issue is an empty object', () => {
      const mockActiveIssue = {};
      expect(getters.groupPathForActiveIssue({}, { activeBoardItem: mockActiveIssue })).toEqual('');
    });
  });

  describe('projectPathByIssueId', () => {
    it('returns project path for the active issue', () => {
      const mockActiveIssue = {
        referencePath: 'gitlab-org/gitlab-test#1',
      };
      expect(getters.projectPathForActiveIssue({}, { activeBoardItem: mockActiveIssue })).toEqual(
        'gitlab-org/gitlab-test',
      );
    });

    it('returns empty string as project path when active issue is an empty object', () => {
      const mockActiveIssue = {};
      expect(getters.projectPathForActiveIssue({}, { activeBoardItem: mockActiveIssue })).toEqual(
        '',
      );
    });
  });

  describe('getBoardItemsByList', () => {
    const boardsState = {
      boardItemsByListId: mockIssuesByListId,
      boardItems: issues,
    };
    it('returns issues for a given listId', () => {
      const getBoardItemById = (issueId) =>
        [mockIssue, mockIssue2].find(({ id }) => id === issueId);

      expect(
        getters.getBoardItemsByList(boardsState, { getBoardItemById })('gid://gitlab/List/2'),
      ).toEqual(mockIssues);
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

  describe('activeGroupProjects', () => {
    const state = {
      groupProjects: [mockGroupProject1, mockArchivedGroupProject],
    };

    it('returns only returns non-archived group projects', () => {
      expect(getters.activeGroupProjects(state)).toEqual([mockGroupProject1]);
    });
  });

  describe('isIssueBoard', () => {
    it.each`
      issuableType | expected
      ${'issue'}   | ${true}
      ${'epic'}    | ${false}
    `(
      'returns $expected when issuableType on state is $issuableType',
      ({ issuableType, expected }) => {
        const state = {
          issuableType,
        };

        expect(getters.isIssueBoard(state)).toBe(expected);
      },
    );
  });

  describe('isEpicBoard', () => {
    afterEach(() => {
      window.gon = { features: {} };
    });

    it('returns false', () => {
      expect(getters.isEpicBoard()).toBe(false);
    });
  });
});
