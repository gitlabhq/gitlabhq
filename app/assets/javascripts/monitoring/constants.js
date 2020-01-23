import { __ } from '~/locale';

export const PROMETHEUS_TIMEOUT = 120000; // TWO_MINUTES

/**
 * States and error states in Prometheus Queries (PromQL) for metrics
 */
export const metricStates = {
  /**
   * Metric data is available
   */
  OK: 'OK',

  /**
   * Metric data is being fetched
   */
  LOADING: 'LOADING',

  /**
   * Connection timed out to prometheus server
   * the timeout is set to PROMETHEUS_TIMEOUT
   *
   */
  TIMEOUT: 'TIMEOUT',

  /**
   * The prometheus server replies with an empty data set
   */
  NO_DATA: 'NO_DATA',

  /**
   * The prometheus server cannot be reached
   */
  CONNECTION_FAILED: 'CONNECTION_FAILED',

  /**
   * The prometheus server was reached but it cannot process
   * the query. This can happen for several reasons:
   * - PromQL syntax is incorrect
   * - An operator is not supported
   */
  BAD_QUERY: 'BAD_QUERY',

  /**
   * No specific reason found for error
   */
  UNKNOWN_ERROR: 'UNKNOWN_ERROR',
};

export const sidebarAnimationDuration = 300; // milliseconds.

export const chartHeight = 300;

export const graphTypes = {
  deploymentData: 'scatter',
};

export const symbolSizes = {
  anomaly: 8,
  default: 14,
};

export const areaOpacityValues = {
  default: 0.2,
};

export const colorValues = {
  primaryColor: '#1f78d1', // $blue-500 (see variables.scss)
  anomalySymbol: '#db3b21',
  anomalyAreaColor: '#1f78d1',
};

export const lineTypes = {
  default: 'solid',
};

export const lineWidths = {
  default: 2,
};

export const dateFormats = {
  timeOfDay: 'h:MM TT',
  default: 'dd mmm yyyy, h:MMTT',
};

export const datePickerTimeWindows = {
  thirtyMinutes: {
    label: __('30 minutes'),
    seconds: 60 * 30,
  },
  threeHours: {
    label: __('3 hours'),
    seconds: 60 * 60 * 3,
  },
  eightHours: {
    label: __('8 hours'),
    seconds: 60 * 60 * 8,
    default: true,
  },
  oneDay: {
    label: __('1 day'),
    seconds: 60 * 60 * 24 * 1,
  },
  threeDays: {
    label: __('3 days'),
    seconds: 60 * 60 * 24 * 3,
  },
  oneWeek: {
    label: __('1 week'),
    seconds: 60 * 60 * 24 * 7 * 1,
  },
  twoWeeks: {
    label: __('2 weeks'),
    seconds: 60 * 60 * 24 * 7 * 2,
  },
};
