import { s__, __, sprintf } from '~/locale';
import query from '../graphql/queries/usage_count.query.graphql';

const noDataMessage = s__('UsageTrends|No data available.');

export default [
  {
    loadChartError: sprintf(
      s__('UsageTrends|Could not load the pipelines chart. Please refresh the page to try again.'),
    ),
    noDataMessage,
    chartTitle: s__('UsageTrends|Pipelines'),
    yAxisTitle: s__('UsageTrends|Items'),
    xAxisTitle: s__('UsageTrends|Month'),
    queries: [
      {
        query,
        title: s__('UsageTrends|Pipelines total'),
        identifier: 'PIPELINES',
        loadError: sprintf(s__('UsageTrends|There was an error fetching the total pipelines')),
      },
      {
        query,
        title: s__('UsageTrends|Pipelines succeeded'),
        identifier: 'PIPELINES_SUCCEEDED',
        loadError: sprintf(s__('UsageTrends|There was an error fetching the successful pipelines')),
      },
      {
        query,
        title: s__('UsageTrends|Pipelines failed'),
        identifier: 'PIPELINES_FAILED',
        loadError: sprintf(s__('UsageTrends|There was an error fetching the failed pipelines')),
      },
      {
        query,
        title: s__('UsageTrends|Pipelines canceled'),
        identifier: 'PIPELINES_CANCELED',
        loadError: sprintf(s__('UsageTrends|There was an error fetching the cancelled pipelines')),
      },
      {
        query,
        title: s__('UsageTrends|Pipelines skipped'),
        identifier: 'PIPELINES_SKIPPED',
        loadError: sprintf(s__('UsageTrends|There was an error fetching the skipped pipelines')),
      },
    ],
  },
  {
    loadChartError: sprintf(
      s__(
        'UsageTrends|Could not load the issues and merge requests chart. Please refresh the page to try again.',
      ),
    ),
    noDataMessage,
    chartTitle: s__('UsageTrends|Issues & Merge Requests'),
    yAxisTitle: s__('UsageTrends|Items'),
    xAxisTitle: s__('UsageTrends|Month'),
    queries: [
      {
        query,
        title: __('Issues'),
        identifier: 'ISSUES',
        loadError: sprintf(s__('UsageTrends|There was an error fetching the issues')),
      },
      {
        query,
        title: __('Merge requests'),
        identifier: 'MERGE_REQUESTS',
        loadError: sprintf(s__('UsageTrends|There was an error fetching the merge requests')),
      },
    ],
  },
];
