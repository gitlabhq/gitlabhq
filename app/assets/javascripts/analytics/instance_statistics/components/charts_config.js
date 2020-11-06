import { s__, __, sprintf } from '~/locale';
import query from '../graphql/queries/instance_count.query.graphql';

const noDataMessage = s__('InstanceStatistics|No data available.');

export default [
  {
    loadChartError: sprintf(
      s__(
        'InstanceStatistics|Could not load the pipelines chart. Please refresh the page to try again.',
      ),
    ),
    noDataMessage,
    chartTitle: s__('InstanceStatistics|Pipelines'),
    yAxisTitle: s__('InstanceStatistics|Items'),
    xAxisTitle: s__('InstanceStatistics|Month'),
    queries: [
      {
        query,
        title: s__('InstanceStatistics|Pipelines total'),
        identifier: 'PIPELINES',
        loadError: sprintf(
          s__('InstanceStatistics|There was an error fetching the total pipelines'),
        ),
      },
      {
        query,
        title: s__('InstanceStatistics|Pipelines succeeded'),
        identifier: 'PIPELINES_SUCCEEDED',
        loadError: sprintf(
          s__('InstanceStatistics|There was an error fetching the successful pipelines'),
        ),
      },
      {
        query,
        title: s__('InstanceStatistics|Pipelines failed'),
        identifier: 'PIPELINES_FAILED',
        loadError: sprintf(
          s__('InstanceStatistics|There was an error fetching the failed pipelines'),
        ),
      },
      {
        query,
        title: s__('InstanceStatistics|Pipelines canceled'),
        identifier: 'PIPELINES_CANCELED',
        loadError: sprintf(
          s__('InstanceStatistics|There was an error fetching the cancelled pipelines'),
        ),
      },
      {
        query,
        title: s__('InstanceStatistics|Pipelines skipped'),
        identifier: 'PIPELINES_SKIPPED',
        loadError: sprintf(
          s__('InstanceStatistics|There was an error fetching the skipped pipelines'),
        ),
      },
    ],
  },
  {
    loadChartError: sprintf(
      s__(
        'InstanceStatistics|Could not load the issues and merge requests chart. Please refresh the page to try again.',
      ),
    ),
    noDataMessage,
    chartTitle: s__('InstanceStatistics|Issues & Merge Requests'),
    yAxisTitle: s__('InstanceStatistics|Items'),
    xAxisTitle: s__('InstanceStatistics|Month'),
    queries: [
      {
        query,
        title: __('Issues'),
        identifier: 'ISSUES',
        loadError: sprintf(s__('InstanceStatistics|There was an error fetching the issues')),
      },
      {
        query,
        title: __('Merge requests'),
        identifier: 'MERGE_REQUESTS',
        loadError: sprintf(
          s__('InstanceStatistics|There was an error fetching the merge requests'),
        ),
      },
    ],
  },
];
