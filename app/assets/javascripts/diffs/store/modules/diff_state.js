import Cookies from 'js-cookie';
import { getParameterValues } from '~/lib/utils/url_utility';
import bp from '~/breakpoints';
import { INLINE_DIFF_VIEW_TYPE, DIFF_VIEW_COOKIE_NAME, MR_TREE_SHOW_KEY } from '../../constants';

const viewTypeFromQueryString = getParameterValues('view')[0];
const viewTypeFromCookie = Cookies.get(DIFF_VIEW_COOKIE_NAME);
const defaultViewType = INLINE_DIFF_VIEW_TYPE;
const storedTreeShow = localStorage.getItem(MR_TREE_SHOW_KEY);

export default () => ({
  isLoading: true,
  endpoint: '',
  basePath: '',
  commit: null,
  startVersion: null,
  diffFiles: [],
  mergeRequestDiffs: [],
  mergeRequestDiff: null,
  diffLineCommentForms: {},
  diffViewType: viewTypeFromQueryString || viewTypeFromCookie || defaultViewType,
  tree: [],
  treeEntries: {},
  showTreeList:
    storedTreeShow === null ? bp.getBreakpointSize() !== 'xs' : storedTreeShow === 'true',
  currentDiffFileId: '',
  projectPath: '',
  commentForms: [],
});
