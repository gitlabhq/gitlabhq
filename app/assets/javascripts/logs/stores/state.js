import { convertToFixedRange } from '~/lib/utils/datetime_range';
import { timeRanges, defaultTimeRange } from '~/vue_shared/constants';

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
    // Selected time range, can be fixed or relative
    selected: defaultTimeRange,
    // Current time range, must be fixed
    current: convertToFixedRange(defaultTimeRange),

    invalidWarning: false,
  },

  /**
   * Environments list information
   */
  environments: {
    options: [],
    isLoading: false,
    current: null,
    fetchError: false,
  },

  /**
   * Logs including trace
   */
  logs: {
    lines: [],
    isLoading: false,
    /**
     * Logs `cursor` represents the current pagination position,
     * Should be sent in next batch (page) of logs to be fetched
     */
    cursor: null,
    isComplete: false,

    fetchError: false,
  },

  /**
   * Pods list information
   */
  pods: {
    options: [],
    current: null,
  },
});
