import { getValueStreamSummaryMetrics } from '~/api/analytics_api';
import { FLOW_METRICS } from '../constants';

const NO_COMMIT_DATA_ERROR = 'No commit data returned';

export const resolvers = {
  Query: {
    flowMetricsCommits(_, { fullPath, startDate, endDate, labelNames, ...params }) {
      return getValueStreamSummaryMetrics(fullPath, {
        ...params,
        created_after: startDate,
        created_before: endDate,
        label_names: labelNames,
      })
        .then(({ data = [] }) => {
          const commits = data.filter((metric) => metric.identifier === FLOW_METRICS.COMMITS);

          if (!commits.length) {
            throw new Error(NO_COMMIT_DATA_ERROR);
          }

          return commits[0];
        })
        .catch((error) => {
          if (error.message !== NO_COMMIT_DATA_ERROR) {
            throw new Error(error);
          }
        });
    },
  },
};
