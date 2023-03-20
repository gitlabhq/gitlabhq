import { getCookie } from '~/lib/utils/common_utils';
import { getParameterValues } from '~/lib/utils/url_utility';
import { INLINE_DIFF_VIEW_TYPE, DIFF_VIEW_COOKIE_NAME } from '../../constants';

const getViewTypeFromQueryString = () => getParameterValues('view')[0];

const viewTypeFromCookie = getCookie(DIFF_VIEW_COOKIE_NAME);
const defaultViewType = INLINE_DIFF_VIEW_TYPE;

export default () => ({
  isLoading: true,
  isTreeLoaded: false,
  batchLoadingState: null,
  retrievingBatches: false,
  addedLines: null,
  removedLines: null,
  endpoint: '',
  endpointUpdateUser: '',
  endpointDiffForPath: '',
  basePath: '',
  commit: null,
  startVersion: null, // Null unless a target diff is selected for comparison that is not the "base" diff
  diffFiles: [],
  coverageFiles: {},
  coverageLoaded: false,
  mergeRequestDiffs: [],
  mergeRequestDiff: null,
  diffViewType: getViewTypeFromQueryString() || viewTypeFromCookie || defaultViewType,
  tree: [],
  treeEntries: {},
  showTreeList: true,
  currentDiffFileId: '',
  projectPath: '',
  viewedDiffFileIds: {},
  commentForms: [],
  highlightedRow: null,
  renderTreeList: true,
  showWhitespace: true,
  viewDiffsFileByFile: false,
  fileFinderVisible: false,
  dismissEndpoint: '',
  showSuggestPopover: true,
  defaultSuggestionCommitMessage: '',
  mrReviews: {},
  latestDiff: true,
  disableVirtualScroller: false,
});
