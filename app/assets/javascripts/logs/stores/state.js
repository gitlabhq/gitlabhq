import { timeRanges, defaultTimeRange } from '~/monitoring/constants';

export default () => ({
  /**
   * Full text search
   */
  search: '',

  /**
   * Time range (Show last)
   */
  timeRange: {
    options: timeRanges,
    current: defaultTimeRange,
  },

  /**
   * Environments list information
   */
  environments: {
    options: [],
    isLoading: false,
    current: null,
  },

  /**
   * Logs including trace
   */
  logs: {
    lines: [],
    isLoading: false,
    isComplete: true,
  },

  /**
   * Pods list information
   */
  pods: {
    options: [],
    current: null,
  },
});
