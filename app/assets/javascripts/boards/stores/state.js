import { inactiveId } from '~/boards/constants';

export default () => ({
  boardType: null,
  fullPath: null,
  disabled: false,
  isShowingLabels: true,
  activeId: inactiveId,
  sidebarType: '',
  boardLists: {},
  listsFlags: {},
  boardItemsByListId: {},
  isSettingAssignees: false,
  pageInfoByListId: {},
  boardItems: {},
  filterParams: {},
  boardConfig: {},
  labels: [],
  highlightedLists: [],
  selectedBoardItems: [],
  groupProjects: [],
  groupProjectsFlags: {
    isLoading: false,
    isLoadingMore: false,
    pageInfo: {},
  },
  selectedProject: {},
  error: undefined,
  addColumnFormVisible: false,
  // TODO: remove after ce/ee split of board_content.vue
  isShowingEpicsSwimlanes: false,
});
