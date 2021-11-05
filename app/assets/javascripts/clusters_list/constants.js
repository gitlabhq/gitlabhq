import { __, s__, sprintf } from '~/locale';

export const MAX_LIST_COUNT = 25;
export const INSTALL_AGENT_MODAL_ID = 'install-agent';
export const ACTIVE_CONNECTION_TIME = 480000;
export const TROUBLESHOOTING_LINK =
  'https://docs.gitlab.com/ee/user/clusters/agent/#troubleshooting';

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

export const I18N_INSTALL_AGENT_MODAL = {
  next: __('Next'),
  done: __('Done'),
  cancel: __('Cancel'),

  modalTitle: s__('ClusterAgents|Install new Agent'),

  selectAgentTitle: s__('ClusterAgents|Select which Agent you want to install'),
  selectAgentBody: s__(
    `ClusterAgents|Select the Agent you want to register with GitLab and install on your cluster. To learn more about the Kubernetes Agent registration process %{linkStart}go to the documentation%{linkEnd}.`,
  ),

  copyToken: s__('ClusterAgents|Copy token'),
  tokenTitle: s__('ClusterAgents|Registration token'),
  tokenBody: s__(
    `ClusterAgents|The registration token will be used to connect the Agent on your cluster to GitLab. To learn more about the registration tokens and how they are used %{linkStart}go to the documentation%{linkEnd}.`,
  ),

  tokenSingleUseWarningTitle: s__(
    'ClusterAgents|The token value will not be shown again after you close this window.',
  ),
  tokenSingleUseWarningBody: s__(
    `ClusterAgents|The recommended installation method provided below includes the token. If you want to follow the alternative installation method provided in the docs make sure you save the token value before you close the window.`,
  ),

  basicInstallTitle: s__('ClusterAgents|Recommended installation method'),
  basicInstallBody: __(
    `Open a CLI and connect to the cluster you want to install the Agent in. Use this installation method to minimize any manual steps. The token is already included in the command.`,
  ),

  advancedInstallTitle: s__('ClusterAgents|Alternative installation methods'),
  advancedInstallBody: s__(
    'ClusterAgents|For alternative installation methods %{linkStart}go to the documentation%{linkEnd}.',
  ),

  registrationErrorTitle: __('Failed to register Agent'),
  unknownError: s__('ClusterAgents|An unknown error occurred. Please try again.'),
};

export const I18N_AVAILABLE_AGENTS_DROPDOWN = {
  selectAgent: s__('ClusterAgents|Select an Agent'),
  registeringAgent: s__('ClusterAgents|Registering Agent'),
};

export const AGENT_STATUSES = {
  active: {
    name: s__('ClusterAgents|Connected'),
    icon: 'status-success',
    class: 'text-success-500',
    tooltip: {
      title: sprintf(s__('ClusterAgents|Last connected %{timeAgo}.')),
    },
  },
  inactive: {
    name: s__('ClusterAgents|Not connected'),
    icon: 'severity-critical',
    class: 'text-danger-800',
    tooltip: {
      title: s__('ClusterAgents|Agent might not be connected to GitLab'),
      body: sprintf(
        s__(
          'ClusterAgents|The Agent has not been connected in a long time. There might be a connectivity issue. Last contact was %{timeAgo}.',
        ),
      ),
    },
  },
  unused: {
    name: s__('ClusterAgents|Never connected'),
    icon: 'status-neutral',
    class: 'text-secondary-400',
    tooltip: {
      title: s__('ClusterAgents|Agent never connected to GitLab'),
      body: s__('ClusterAgents|Make sure you are using a valid token.'),
    },
  },
};
