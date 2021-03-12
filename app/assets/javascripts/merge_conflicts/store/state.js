import Cookies from 'js-cookie';
import { VIEW_TYPES } from '../constants';

const diffViewType = Cookies.get('diff_view');

export default () => ({
  isLoading: true,
  hasError: false,
  isSubmitting: false,
  isParallel: diffViewType === VIEW_TYPES.PARALLEL,
  diffViewType,
  conflictsData: {},
});
