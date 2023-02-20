import { find } from 'lodash';
import { TYPE_ISSUE } from '~/issues/constants';
import { inactiveId } from '../constants';

export default {
  isSidebarOpen: (state) => state.activeId !== inactiveId,
  isSwimlanesOn: () => false,
  getBoardItemById: (state) => (id) => {
    return state.boardItems[id] || {};
  },

  getBoardItemsByList: (state, getters) => (listId) => {
    const listItemsIds = state.boardItemsByListId[listId] || [];
    return listItemsIds.map((id) => getters.getBoardItemById(id));
  },

  activeBoardItem: (state) => {
    return state.boardItems[state.activeId] || { iid: '', id: '' };
  },

  groupPathForActiveIssue: (_, getters) => {
    const { referencePath = '' } = getters.activeBoardItem;
    return referencePath.slice(0, referencePath.lastIndexOf('/'));
  },

  projectPathForActiveIssue: (_, getters) => {
    const { referencePath = '' } = getters.activeBoardItem;
    return referencePath.slice(0, referencePath.indexOf('#'));
  },

  activeGroupProjects: (state) => {
    return state.groupProjects.filter((p) => !p.archived);
  },

  getListByLabelId: (state) => (labelId) => {
    if (!labelId) {
      return null;
    }
    return find(state.boardLists, (l) => l.label?.id === labelId);
  },

  getListByTitle: (state) => (title) => {
    return find(state.boardLists, (l) => l.title === title);
  },

  isIssueBoard: (state) => {
    return state.issuableType === TYPE_ISSUE;
  },

  isEpicBoard: () => {
    return false;
  },

  hasScope: (state) => {
    const { boardConfig } = state;
    if (boardConfig.labels?.length > 0) {
      return true;
    }
    let hasScope = false;
    ['assigneeId', 'iterationCadenceId', 'iterationId', 'milestoneId', 'weight'].forEach((attr) => {
      if (boardConfig[attr] !== null && boardConfig[attr] !== undefined) {
        hasScope = true;
      }
    });
    return hasScope;
  },
};
