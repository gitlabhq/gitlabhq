import Cookies from 'js-cookie';
import { getParameterValues } from '~/lib/utils/url_utility';
import actions from '../actions';
import getters from '../getters';
import mutations from '../mutations';
import { INLINE_DIFF_VIEW_TYPE, DIFF_VIEW_COOKIE_NAME } from '../../constants';

const viewTypeFromQueryString = getParameterValues('view')[0];
const viewTypeFromCookie = Cookies.get(DIFF_VIEW_COOKIE_NAME);
const defaultViewType = INLINE_DIFF_VIEW_TYPE;

export default {
  state: {
    isLoading: true,
    endpoint: '',
    commit: null,
    diffFiles: [],
    mergeRequestDiffs: [],
    diffLineCommentForms: {},
    diffViewType: viewTypeFromQueryString || viewTypeFromCookie || defaultViewType,
  },
  getters,
  actions,
  mutations,
};
