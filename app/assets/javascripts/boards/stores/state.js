import { inactiveId, ListType } from '~/boards/constants';

export default () => ({
  boardType: null,
  issuableType: null,
  fullPath: null,
  disabled: false,
  isShowingLabels: true,
  activeId: inactiveId,
  sidebarType: '',
  boardLists: {},
  listsFlags: {},
  boardItemsByListId: {},
  backupItemsList: [],
  isSettingAssignees: false,
  pageInfoByListId: {},
  boardItems: {},
  filterParams: {},
  boardConfig: {},
  labelsLoading: false,
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
  addColumnForm: {
    visible: false,
    columnType: ListType.label,
  },
  // TODO: remove after ce/ee split of board_content.vue
  isShowingEpicsSwimlanes: false,
});
