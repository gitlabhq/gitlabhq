import { find } from 'lodash';
import { inactiveId } from '../constants';

export default {
  labelToggleState: state => (state.isShowingLabels ? 'on' : 'off'),
  isSidebarOpen: state => state.activeId !== inactiveId,
  isSwimlanesOn: state => {
    if (!gon?.features?.boardsWithSwimlanes && !gon?.features?.swimlanes) {
      return false;
    }

    return state.isShowingEpicsSwimlanes;
  },
  getIssueById: state => id => {
    return state.issues[id] || {};
  },

  getIssuesByList: (state, getters) => listId => {
    const listIssueIds = state.issuesByListId[listId] || [];
    return listIssueIds.map(id => getters.getIssueById(id));
  },

  activeIssue: state => {
    return state.issues[state.activeId] || {};
  },

  getListByLabelId: state => labelId => {
    return find(state.boardLists, l => l.label?.id === labelId);
  },

  getListByTitle: state => title => {
    return find(state.boardLists, l => l.title === title);
  },

  shouldUseGraphQL: () => {
    return gon?.features?.graphqlBoardLists;
  },
};
