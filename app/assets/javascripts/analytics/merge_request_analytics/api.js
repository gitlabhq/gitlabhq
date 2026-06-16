import { defaultClient } from '../analytics_dashboards/graphql/client';
import { extractQueryResponseFromNamespace } from '../shared/utils';
import getThroughputChartData from './graphql/queries/throughput_chart.query.graphql';
import { computeMonthRangeData } from './utils';

const QUERY_RESULT_KEY = 'mergeRequests';

const extractThroughputDataForPeriod = ({ month, year, result }) => {
  const data = extractQueryResponseFromNamespace({
    result,
    resultKey: QUERY_RESULT_KEY,
  });
  const hasData = data?.count || data?.totalTimeToMerge;

  return {
    key: `${month}_${year}`,
    // To ensure no gaps in the throughput chart, we need to return `0`s rather than null`s
    data: hasData ? data : { count: 0, totalTimeToMerge: null },
  };
};

const timePeriodToThroughputQuery = async ({
  month,
  year,
  namespace,
  mergedAfter,
  mergedBefore,
  ...params
}) => {
  const result = await defaultClient.query({
    query: getThroughputChartData,
    variables: {
      fullPath: namespace,
      startDate: mergedAfter,
      endDate: mergedBefore,
      ...params,
    },
  });

  return extractThroughputDataForPeriod({ month, year, result });
};

export const queryThroughputData = async ({
  namespace,
  startDate,
  endDate,
  labels = null,
  notLabels = null,
  sourceBranches = null,
  targetBranches = null,
  // The rest should not be set to null
  milestoneTitle,
  notMilestoneTitle,
  assigneeUsername,
  authorUsername,
}) => {
  const monthData = computeMonthRangeData(startDate, endDate);
  const promises = monthData.map(({ year, month, mergedAfter, mergedBefore }) =>
    timePeriodToThroughputQuery({
      year,
      month,
      namespace,
      mergedAfter,
      mergedBefore,
      labels,
      notLabels,
      sourceBranches,
      targetBranches,
      milestoneTitle,
      notMilestoneTitle,
      assigneeUsername,
      authorUsername,
    }),
  );

  const result = await Promise.all(promises);
  return result.reduce(
    (acc, { key, data }) => ({
      ...acc,
      [key]: data,
    }),
    {},
  );
};
