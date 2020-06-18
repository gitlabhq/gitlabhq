import { CHECK_CONFIG, CHECK_RUNNERS } from './constants';

export default () => ({
  checks: {
    [CHECK_CONFIG]: { isLoading: true },
    [CHECK_RUNNERS]: { isLoading: true },
  },
  isVisible: false,
  isShowSplash: true,
  paths: {},
  session: null,
  sessionStatusInterval: 0,
});
