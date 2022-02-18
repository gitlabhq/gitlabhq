import { getCookie } from '~/lib/utils/common_utils';
import { VIEW_TYPES } from '../constants';

const diffViewType = getCookie('diff_view');

export default () => ({
  isLoading: true,
  hasError: false,
  isSubmitting: false,
  isParallel: diffViewType === VIEW_TYPES.PARALLEL,
  diffViewType,
  conflictsData: {},
});
