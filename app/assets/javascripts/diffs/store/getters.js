import { PARALLEL_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE } from '../constants';

export default {
  isParallelView(state) {
    return state.diffViewType === PARALLEL_DIFF_VIEW_TYPE;
  },
  isInlineView(state) {
    return state.diffViewType === INLINE_DIFF_VIEW_TYPE;
  },
};
