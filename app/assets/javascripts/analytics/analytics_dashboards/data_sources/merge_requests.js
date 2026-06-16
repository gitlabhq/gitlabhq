import { dayAfter } from '~/lib/utils/datetime_utility';
import getMergeRequests from '~/analytics/merge_request_analytics/graphql/queries/throughput_table.query.graphql';
import { extractQueryResponseFromNamespace } from '~/analytics/shared/utils';
import {
  DATE_RANGE_OPTIONS,
  DATE_RANGE_OPTION_LAST_365_DAYS,
} from '~/explore/analytics_dashboards/components/constants';
import { filterToMRThroughputQueryObject } from '~/analytics/merge_request_analytics/utils';
import { defaultClient } from '../graphql/client';

const QUERY_RESULT_KEY = 'mergeRequests';

const formatNodes = (list) => {
  return list.map(
    ({
      iid,
      title,
      webUrl,
      createdAt,
      mergedAt,
      diffStatsSummary,
      pipelines,
      milestone,
      labels,
      approvedBy,
      assignees = [],
      commitCount = 0,
      userNotesCount = 0,
    }) => {
      const pipelinesCount = pipelines?.nodes?.length || 0;
      const firstPipeline = pipelinesCount ? pipelines.nodes[0] : undefined;

      const link = {
        iid,
        title,
        webUrl,
        labelsCount: labels?.count,
        userNotesCount,
        approvalCount: approvedBy?.nodes?.length,
        pipelineStatus: firstPipeline?.detailedStatus,
      };

      return {
        link,
        assignees,
        commitCount,
        dateMerged: { timestamp: mergedAt },
        timeToMerge: {
          startTimestamp: createdAt,
          endTimestamp: mergedAt,
        },
        diffStatsSummary,
        pipelinesCount,
        milestone,
      };
    },
  );
};

const fetchMergeRequests = async ({
  namespace,
  startDate,
  endDate,
  labels = null,
  notLabels = null,
  sourceBranches = null,
  targetBranches = null,
  pagination,
  // The rest should not be set to null
  milestoneTitle,
  notMilestoneTitle,
  assigneeUsername,
  authorUsername,
}) =>
  defaultClient
    .query({
      query: getMergeRequests,
      variables: {
        fullPath: namespace,
        startDate,
        endDate,
        labels,
        notLabels,
        sourceBranches,
        targetBranches,
        milestoneTitle,
        notMilestoneTitle,
        assigneeUsername,
        authorUsername,
        firstPageSize: pagination.first,
        lastPageSize: pagination.last,
        nextPageCursor: pagination.endCursor,
        prevPageCursor: pagination.startCursor,
      },
    })
    .then((result) => {
      const { nodes, pageInfo } = extractQueryResponseFromNamespace({
        result,
        resultKey: QUERY_RESULT_KEY,
      });

      if (!nodes?.length) {
        return null;
      }

      return {
        nodes: formatNodes(nodes),
        pageInfo: {
          ...pagination,
          ...pageInfo,
        },
      };
    });

export default function fetch({
  namespace,
  query: { dateRange, pagination, ...overridesRest } = {},
  filters: {
    startDate: filtersStartDate,
    endDate: filtersEndDate,
    searchFilters,
    dateRangeOption,
  } = {},
  setVisualizationOverrides = () => {},
}) {
  const {
    startDate,
    endDate,
    text: subtitle,
  } = DATE_RANGE_OPTIONS[dateRangeOption || dateRange] ||
  DATE_RANGE_OPTIONS[DATE_RANGE_OPTION_LAST_365_DAYS];

  setVisualizationOverrides({ visualizationOptionOverrides: { subtitle } });

  return fetchMergeRequests({
    namespace,
    startDate: filtersStartDate ?? startDate,
    endDate: filtersEndDate ?? dayAfter(endDate, { utc: true }),
    pagination: pagination || { first: 20 },
    ...filterToMRThroughputQueryObject(searchFilters),
    ...overridesRest,
  });
}
