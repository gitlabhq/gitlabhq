import { __, s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const MAX_LIST_COUNT = 25;
export const INSTALL_AGENT_MODAL_ID = 'install-agent';
export const ACTIVE_CONNECTION_TIME = 480000;

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
  registerAgentButton: s__('ClusterAgents|Register Agent'),
  close: __('Close'),
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

export const I18N_AGENTS_EMPTY_STATE = {
  introText: s__(
    'ClusterAgents|Use GitLab Agents to more securely integrate with your clusters to deploy your applications, run your pipelines, use review apps and much more.',
  ),
  multipleClustersText: s__(
    'ClusterAgents|If you are setting up multiple clusters and are using Auto DevOps, %{linkStart}read about using multiple Kubernetes clusters first.%{linkEnd}',
  ),
  learnMoreText: s__('ClusterAgents|Learn more about the GitLab Kubernetes Agent.'),
  warningText: s__(
    'ClusterAgents|To install an Agent you should create an agent directory in the Repository first. We recommend that you add the Agent configuration to the directory before you start the installation process.',
  ),
  readMoreText: s__('ClusterAgents|Read more about getting started'),
  repositoryButtonText: s__('ClusterAgents|Go to the repository'),
  primaryButtonText: s__('ClusterAgents|Connect with a GitLab Agent'),
};

export const I18N_CLUSTERS_EMPTY_STATE = {
  description: s__(
    'ClusterIntegration|Use certificates to integrate with your clusters to deploy your applications, run your pipelines, use review apps and much more in an easy way.',
  ),
  multipleClustersText: s__(
    'ClusterIntegration|If you are setting up multiple clusters and are using Auto DevOps, %{linkStart}read about using multiple Kubernetes clusters first.%{linkEnd}',
  ),
  learnMoreLinkText: s__('ClusterIntegration|Learn more about the GitLab managed clusters'),
  buttonText: s__('ClusterIntegration|Connect with a certificate'),
};

export const AGENT_CARD_INFO = {
  tabName: 'agent',
  title: sprintf(s__('ClusterAgents|%{number} of %{total} Agent based integrations')),
  emptyTitle: s__('ClusterAgents|No Agent based integrations'),
  tooltip: {
    label: s__('ClusterAgents|Recommended'),
    title: s__('ClusterAgents|GitLab Agents'),
    text: sprintf(
      s__(
        'ClusterAgents|GitLab Agents provide an increased level of security when integrating with clusters. %{linkStart}Learn more about the GitLab Kubernetes Agent.%{linkEnd}',
      ),
    ),
    link: helpPagePath('user/clusters/agent/index'),
  },
  actionText: s__('ClusterAgents|Install new Agent'),
  footerText: sprintf(s__('ClusterAgents|View all %{number} Agent based integrations')),
};

export const CERTIFICATE_BASED_CARD_INFO = {
  tabName: 'certificate_based',
  title: sprintf(s__('ClusterAgents|%{number} of %{total} Certificate based integrations')),
  emptyTitle: s__('ClusterAgents|No Certificate based integrations'),
  actionText: s__('ClusterAgents|Connect existing cluster'),
  footerText: sprintf(s__('ClusterAgents|View all %{number} Certificate based integrations')),
};

export const MAX_CLUSTERS_LIST = 6;

export const CLUSTERS_TABS = [
  {
    title: s__('ClusterAgents|All'),
    component: 'ClustersViewAll',
    queryParamValue: 'all',
  },
  {
    title: s__('ClusterAgents|Agent'),
    component: 'agents',
    queryParamValue: 'agent',
  },
  {
    title: s__('ClusterAgents|Certificate based'),
    component: 'clusters',
    queryParamValue: 'certificate_based',
  },
];

export const CLUSTERS_ACTIONS = {
  actionsButton: s__('ClusterAgents|Actions'),
  createNewCluster: s__('ClusterAgents|Create new cluster'),
  connectWithAgent: s__('ClusterAgents|Connect with Agent'),
  connectExistingCluster: s__('ClusterAgents|Connect with certificate'),
};

export const AGENT = 'agent';
export const CERTIFICATE_BASED = 'certificate_based';
