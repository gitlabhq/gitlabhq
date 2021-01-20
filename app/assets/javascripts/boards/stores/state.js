import { inactiveId } from '~/boards/constants';

export default () => ({
  boardType: null,
  disabled: false,
  isShowingLabels: true,
  activeId: inactiveId,
  sidebarType: '',
  boardLists: {},
  listsFlags: {},
  issuesByListId: {},
  isSettingAssignees: false,
  pageInfoByListId: {},
  issues: {},
  filterParams: {},
  boardConfig: {},
  groupProjects: [],
  groupProjectsFlags: {
    isLoading: false,
    isLoadingMore: false,
    pageInfo: {},
  },
  selectedProject: {},
  error: undefined,
  // TODO: remove after ce/ee split of board_content.vue
  isShowingEpicsSwimlanes: false,
});
