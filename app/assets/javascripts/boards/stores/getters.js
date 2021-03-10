import { find } from 'lodash';
import { BoardType, inactiveId } from '../constants';

export default {
  isGroupBoard: (state) => state.boardType === BoardType.group,
  isProjectBoard: (state) => state.boardType === BoardType.project,
  isSidebarOpen: (state) => state.activeId !== inactiveId,
  isSwimlanesOn: () => false,
  getBoardItemById: (state) => (id) => {
    return state.boardItems[id] || {};
  },

  getBoardItemsByList: (state, getters) => (listId) => {
    const listItemsIds = state.boardItemsByListId[listId] || [];
    return listItemsIds.map((id) => getters.getBoardItemById(id));
  },

  activeIssue: (state) => {
    return state.boardItems[state.activeId] || {};
  },

  groupPathForActiveIssue: (_, getters) => {
    const { referencePath = '' } = getters.activeIssue;
    return referencePath.slice(0, referencePath.indexOf('/'));
  },

  projectPathForActiveIssue: (_, getters) => {
    const { referencePath = '' } = getters.activeIssue;
    return referencePath.slice(0, referencePath.indexOf('#'));
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

  isEpicBoard: () => {
    return false;
  },

  shouldUseGraphQL: () => {
    return gon?.features?.graphqlBoardLists;
  },
};
