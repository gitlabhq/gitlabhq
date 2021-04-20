import { s__, __ } from '~/locale';
import query from '../graphql/queries/usage_count.query.graphql';

const noDataMessage = s__('UsageTrends|No data available.');

export default [
  {
    loadChartError: s__(
      'UsageTrends|Could not load the projects and groups chart. Please refresh the page to try again.',
    ),
    noDataMessage,
    chartTitle: s__('UsageTrends|Total projects & groups'),
    yAxisTitle: s__('UsageTrends|Total projects & groups'),
    xAxisTitle: s__('UsageTrends|Month'),
    queries: [
      {
        query,
        title: s__('UsageTrends|Total projects'),
        identifier: 'PROJECTS',
        loadError: s__('UsageTrends|There was an error fetching the projects. Please try again.'),
      },
      {
        query,
        title: s__('UsageTrends|Total groups'),
        identifier: 'GROUPS',
        loadError: s__('UsageTrends|There was an error fetching the groups. Please try again.'),
      },
    ],
  },
  {
    loadChartError: s__(
      'UsageTrends|Could not load the pipelines chart. Please refresh the page to try again.',
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
        loadError: s__(
          'UsageTrends|There was an error fetching the total pipelines. Please try again.',
        ),
      },
      {
        query,
        title: s__('UsageTrends|Pipelines succeeded'),
        identifier: 'PIPELINES_SUCCEEDED',
        loadError: s__(
          'UsageTrends|There was an error fetching the successful pipelines. Please try again.',
        ),
      },
      {
        query,
        title: s__('UsageTrends|Pipelines failed'),
        identifier: 'PIPELINES_FAILED',
        loadError: s__(
          'UsageTrends|There was an error fetching the failed pipelines. Please try again.',
        ),
      },
      {
        query,
        title: s__('UsageTrends|Pipelines canceled'),
        identifier: 'PIPELINES_CANCELED',
        loadError: s__(
          'UsageTrends|There was an error fetching the cancelled pipelines. Please try again.',
        ),
      },
      {
        query,
        title: s__('UsageTrends|Pipelines skipped'),
        identifier: 'PIPELINES_SKIPPED',
        loadError: s__(
          'UsageTrends|There was an error fetching the skipped pipelines. Please try again.',
        ),
      },
    ],
  },
  {
    loadChartError: s__(
      'UsageTrends|Could not load the issues and merge requests chart. Please refresh the page to try again.',
    ),
    noDataMessage,
    chartTitle: s__('UsageTrends|Issues & merge requests'),
    yAxisTitle: s__('UsageTrends|Items'),
    xAxisTitle: s__('UsageTrends|Month'),
    queries: [
      {
        query,
        title: __('Issues'),
        identifier: 'ISSUES',
        loadError: s__('UsageTrends|There was an error fetching the issues. Please try again.'),
      },
      {
        query,
        title: __('Merge requests'),
        identifier: 'MERGE_REQUESTS',
        loadError: s__(
          'UsageTrends|There was an error fetching the merge requests. Please try again.',
        ),
      },
    ],
  },
];
