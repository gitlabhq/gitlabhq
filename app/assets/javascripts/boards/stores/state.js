import { inactiveId } from '~/boards/constants';

export default () => ({
  endpoints: {},
  boardType: null,
  isShowingLabels: true,
  activeId: inactiveId,
  issuesByListId: {},
  isLoadingIssues: false,
  listIssueFetchFailure: false,
});
