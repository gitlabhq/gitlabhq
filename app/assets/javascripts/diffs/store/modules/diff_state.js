import Cookies from 'js-cookie';
import { getParameterValues } from '~/lib/utils/url_utility';
import { INLINE_DIFF_VIEW_TYPE, DIFF_VIEW_COOKIE_NAME } from '../../constants';

const viewTypeFromQueryString = getParameterValues('view')[0];
const viewTypeFromCookie = Cookies.get(DIFF_VIEW_COOKIE_NAME);
const defaultViewType = INLINE_DIFF_VIEW_TYPE;

export default () => ({
  isLoading: true,
  endpoint: '',
  basePath: '',
  commit: null,
  diffFiles: [],
  mergeRequestDiffs: [],
  diffLineCommentForms: {},
  diffViewType: viewTypeFromQueryString || viewTypeFromCookie || defaultViewType,
});
