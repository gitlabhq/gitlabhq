import { inactiveId } from '~/boards/constants';

export default () => ({
  endpoints: {},
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
  error: undefined,
  // TODO: remove after ce/ee split of board_content.vue
  isShowingEpicsSwimlanes: false,
});
