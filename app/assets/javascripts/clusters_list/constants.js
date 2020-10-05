import { __, s__ } from '~/locale';

export const CLUSTER_ERRORS = {
  default: {
    tableText: s__('ClusterIntegration|Unknown Error'),
    title: s__('ClusterIntegration|Unknown Error'),
    description: s__(
      'ClusterIntegration|An unknown error occurred while attempting to connect to Kubernetes.',
    ),
    troubleshootingTips: [
      s__('ClusterIntegration|Check your cluster status'),
      s__('ClusterIntegration|Make sure your API endpoint is correct'),
      s__(
        'ClusterIntegration|Node calculations use the Kubernetes Metrics API. Make sure your cluster has metrics installed',
      ),
    ],
  },
  authentication_error: {
    tableText: s__('ClusterIntegration|Unable to Authenticate'),
    title: s__('ClusterIntegration|Authentication Error'),
    description: s__('ClusterIntegration|GitLab failed to authenticate.'),
    troubleshootingTips: [
      s__('ClusterIntegration|Check your token'),
      s__('ClusterIntegration|Check your CA certificate'),
    ],
  },
  connection_error: {
    tableText: s__('ClusterIntegration|Unable to Connect'),
    title: s__('ClusterIntegration|Connection Error'),
    description: s__('ClusterIntegration|GitLab failed to connect to the cluster.'),
    troubleshootingTips: [
      s__('ClusterIntegration|Check your cluster status'),
      s__('ClusterIntegration|Make sure your API endpoint is correct'),
    ],
  },
  http_error: {
    tableText: s__('ClusterIntegration|Unable to Connect'),
    title: s__('ClusterIntegration|HTTP Error'),
    description: s__('ClusterIntegration|There was an HTTP error when connecting to your cluster.'),
    troubleshootingTips: [s__('ClusterIntegration|Check your cluster status')],
  },
};

export const CLUSTER_TYPES = {
  project_type: __('Project'),
  group_type: __('Group'),
  instance_type: __('Instance'),
};

export const MAX_REQUESTS = 3;

export const STATUSES = {
  default: { className: 'bg-white', title: __('Unknown') },
  disabled: { className: 'disabled', title: __('Disabled') },
  created: { className: 'bg-success', title: __('Connected') },
  unreachable: { className: 'bg-danger', title: __('Unreachable') },
  authentication_failure: { className: 'bg-warning', title: __('Authentication Failure') },
  deleting: { title: __('Deleting') },
  creating: { title: __('Creating') },
};
