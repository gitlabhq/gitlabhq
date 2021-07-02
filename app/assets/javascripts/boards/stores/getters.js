import { find } from 'lodash';
import { BoardType, inactiveId, issuableTypes } from '../constants';

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

  activeBoardItem: (state) => {
    return state.boardItems[state.activeId] || { iid: '', id: '', fullId: '' };
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
    return state.issuableType === issuableTypes.issue;
  },

  isEpicBoard: () => {
    return false;
  },

  shouldUseGraphQL: () => {
    return gon?.features?.graphqlBoardLists;
  },
};
