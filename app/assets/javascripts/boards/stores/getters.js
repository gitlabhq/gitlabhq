import { find } from 'lodash';
import { inactiveId } from '../constants';

export default {
  labelToggleState: state => (state.isShowingLabels ? 'on' : 'off'),
  isSidebarOpen: state => state.activeId !== inactiveId,
  isSwimlanesOn: () => false,
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

  projectPathForActiveIssue: (_, getters) => {
    const referencePath = getters.activeIssue.referencePath || '';
    return referencePath.slice(0, referencePath.indexOf('#'));
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
