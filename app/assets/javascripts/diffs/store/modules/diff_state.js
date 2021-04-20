import Cookies from 'js-cookie';
import { getParameterValues } from '~/lib/utils/url_utility';
import {
  INLINE_DIFF_VIEW_TYPE,
  DIFF_VIEW_COOKIE_NAME,
  DIFF_WHITESPACE_COOKIE_NAME,
} from '../../constants';

import { fileByFile } from '../../utils/preferences';
import { getDefaultWhitespace } from '../utils';

const getViewTypeFromQueryString = () => getParameterValues('view')[0];

const viewTypeFromCookie = Cookies.get(DIFF_VIEW_COOKIE_NAME);
const defaultViewType = INLINE_DIFF_VIEW_TYPE;
const whiteSpaceFromQueryString = getParameterValues('w')[0];
const whiteSpaceFromCookie = Cookies.get(DIFF_WHITESPACE_COOKIE_NAME);

export default () => ({
  isLoading: true,
  isTreeLoaded: false,
  isBatchLoading: false,
  retrievingBatches: false,
  addedLines: null,
  removedLines: null,
  endpoint: '',
  endpointUpdateUser: '',
  basePath: '',
  commit: null,
  startVersion: null, // Null unless a target diff is selected for comparison that is not the "base" diff
  diffFiles: [],
  coverageFiles: {},
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
  showWhitespace: getDefaultWhitespace(whiteSpaceFromQueryString, whiteSpaceFromCookie),
  viewDiffsFileByFile: fileByFile(),
  fileFinderVisible: false,
  dismissEndpoint: '',
  showSuggestPopover: true,
  defaultSuggestionCommitMessage: '',
  mrReviews: {},
  latestDiff: true,
});
