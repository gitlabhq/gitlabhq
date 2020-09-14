import { inactiveId } from '../constants';

export default {
  getLabelToggleState: state => (state.isShowingLabels ? 'on' : 'off'),
  isSidebarOpen: state => state.activeId !== inactiveId,
  isSwimlanesOn: state => {
    if (!gon?.features?.boardsWithSwimlanes) {
      return false;
    }

    return state.isShowingEpicsSwimlanes;
  },
  getIssueById: state => id => {
    return state.issues[id] || {};
  },

  getIssues: (state, getters) => listId => {
    const listIssueIds = state.issuesByListId[listId] || [];
    return listIssueIds.map(id => getters.getIssueById(id));
  },

  getActiveIssue: state => {
    return state.issues[state.activeId] || {};
  },
};
