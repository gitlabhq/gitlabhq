import { secondsIn, timeWindowsKeyNames } from './constants';

const secondsToMilliseconds = seconds => seconds * 1000;

export const getTimeDiff = timeWindow => {
  const end = Math.floor(Date.now() / 1000); // convert milliseconds to seconds
  const difference = secondsIn[timeWindow] || secondsIn.eightHours;
  const start = end - difference;

  return {
    start: new Date(secondsToMilliseconds(start)).toISOString(),
    end: new Date(secondsToMilliseconds(end)).toISOString(),
  };
};

export const getTimeWindow = ({ start, end }) =>
  Object.entries(secondsIn).reduce((acc, [timeRange, value]) => {
    if (new Date(end) - new Date(start) === secondsToMilliseconds(value)) {
      return timeRange;
    }
    return acc;
  }, timeWindowsKeyNames.eightHours);

/**
 * This method is used to validate if the graph data format for a chart component
 * that needs a time series as a response from a prometheus query (query_range) is
 * of a valid format or not.
 * @param {Object} graphData  the graph data response from a prometheus request
 * @returns {boolean} whether the graphData format is correct
 */
export const graphDataValidatorForValues = (isValues, graphData) => {
  const responseValueKeyName = isValues ? 'value' : 'values';

  return (
    Array.isArray(graphData.queries) &&
    graphData.queries.filter(query => {
      if (Array.isArray(query.result)) {
        return (
          query.result.filter(res => Array.isArray(res[responseValueKeyName])).length ===
          query.result.length
        );
      }
      return false;
    }).length === graphData.queries.length
  );
};

/* eslint-disable @gitlab/i18n/no-non-i18n-strings */
/**
 * Checks that element that triggered event is located on cluster health check dashboard
 * @param {HTMLElement}  element to check against
 * @returns {boolean}
 */
const isClusterHealthBoard = () => (document.body.dataset.page || '').includes(':clusters:show');

/**
 * Tracks snowplow event when user generates link to metric chart
 * @param {String}  chart link that will be sent as a property for the event
 * @return {Object} config object for event tracking
 */
export const generateLinkToChartOptions = chartLink => {
  const isCLusterHealthBoard = isClusterHealthBoard();

  const category = isCLusterHealthBoard
    ? 'Cluster Monitoring'
    : 'Incident Management::Embedded metrics';
  const action = isCLusterHealthBoard
    ? 'generate_link_to_cluster_metric_chart'
    : 'generate_link_to_metrics_chart';

  return { category, action, label: 'Chart link', property: chartLink };
};

/**
 * Tracks snowplow event when user downloads CSV of cluster metric
 * @param {String}  chart title that will be sent as a property for the event
 */
export const downloadCSVOptions = title => {
  const isCLusterHealthBoard = isClusterHealthBoard();

  const category = isCLusterHealthBoard
    ? 'Cluster Monitoring'
    : 'Incident Management::Embedded metrics';
  const action = isCLusterHealthBoard
    ? 'download_csv_of_cluster_metric_chart'
    : 'download_csv_of_metrics_dashboard_chart';

  return { category, action, label: 'Chart title', property: title };
};

export default {};
