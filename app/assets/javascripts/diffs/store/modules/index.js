import Cookies from 'js-cookie';
import * as actions from '../actions';
import getters from '../getters';
import mutations from '../mutations';
import { INLINE_DIFF_VIEW_TYPE, DIFF_VIEW_COOKIE_NAME } from '../../constants';

export default {
  state: {
    isLoading: true,
    endpoint: '',
    diffFiles: [],
    mergeRequestDiffs: [],
    diffLineCommentForms: {},
    diffViewType: Cookies.get(DIFF_VIEW_COOKIE_NAME) || INLINE_DIFF_VIEW_TYPE,
  },
  getters,
  actions,
  mutations,
};
