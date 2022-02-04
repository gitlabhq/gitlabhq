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

export const I18N_AGENT_TABLE = {
  nameLabel: s__('ClusterAgents|Name'),
  statusLabel: s__('ClusterAgents|Connection status'),
  lastContactLabel: s__('ClusterAgents|Last contact'),
  versionLabel: __('Version'),
  configurationLabel: s__('ClusterAgents|Configuration'),
  optionsLabel: __('Options'),
  troubleshootingText: s__('ClusterAgents|Learn how to troubleshoot'),
  neverConnectedText: s__('ClusterAgents|Never'),
  versionMismatchTitle: s__('ClusterAgents|Agent version mismatch'),
  versionMismatchText: s__(
    "ClusterAgents|The Agent version do not match each other across your cluster's pods. This can happen when a new Agent version was just deployed and Kubernetes is shutting down the old pods.",
  ),
  versionOutdatedTitle: s__('ClusterAgents|Agent version update required'),
  versionOutdatedText: s__(
    'ClusterAgents|Your Agent version is out of sync with your GitLab version (v%{version}), which might cause compatibility problems. Update the Agent installed on your cluster to the most recent version.',
  ),
  versionMismatchOutdatedTitle: s__('ClusterAgents|Agent version mismatch and update'),
  viewDocsText: s__('ClusterAgents|How to update the Agent?'),
};

export const I18N_AGENT_MODAL = {
  agent_registration: {
    registerAgentButton: s__('ClusterAgents|Register'),
    close: __('Close'),
    cancel: __('Cancel'),

    modalTitle: s__('ClusterAgents|Connect a cluster through the Agent'),
    selectAgentTitle: s__('ClusterAgents|Select an agent to register with GitLab'),
    selectAgentBody: s__(
      'ClusterAgents|Register an agent to generate a token that will be used to install the agent on your cluster in the next step.',
    ),
    learnMoreLink: s__('ClusterAgents|How to register an agent?'),

    copyToken: s__('ClusterAgents|Copy token'),
    tokenTitle: s__('ClusterAgents|Registration token'),
    tokenBody: s__(
      `ClusterAgents|The registration token will be used to connect the agent on your cluster to GitLab. %{linkStart}What are registration tokens?%{linkEnd}`,
    ),

    tokenSingleUseWarningTitle: s__(
      'ClusterAgents|You cannot see this token again after you close this window.',
    ),
    tokenSingleUseWarningBody: s__(
      `ClusterAgents|The recommended installation method includes the token. If you want to follow the advanced installation method provided in the docs, make sure you save the token value before you close this window.`,
    ),

    basicInstallTitle: s__('ClusterAgents|Recommended installation method'),
    basicInstallBody: __(
      `Open a CLI and connect to the cluster you want to install the agent in. Use this installation method to minimize any manual steps. The token is already included in the command.`,
    ),

    advancedInstallTitle: s__('ClusterAgents|Advanced installation methods'),
    advancedInstallBody: s__(
      'ClusterAgents|For the advanced installation method %{linkStart}see the documentation%{linkEnd}.',
    ),

    registrationErrorTitle: s__('ClusterAgents|Failed to register an agent'),
    unknownError: s__('ClusterAgents|An unknown error occurred. Please try again.'),
  },
  empty_state: {
    modalTitle: s__('ClusterAgents|Connect your cluster through the Agent'),
    modalBody: s__(
      "ClusterAgents|To install a new agent, first add the agent's configuration file to this repository. %{linkStart}Learn more about installing GitLab Agent.%{linkEnd}",
    ),
    enableKasText: s__(
      "ClusterAgents|Your instance doesn't have the %{linkStart}GitLab Agent Server (KAS)%{linkEnd} set up. Ask a GitLab Administrator to install it.",
    ),
    altText: s__('ClusterAgents|GitLab Agent for Kubernetes'),
    primaryButton: s__('ClusterAgents|Go to the repository files'),
    done: __('Cancel'),
  },
};

export const KAS_DISABLED_ERROR = 'Gitlab::Kas::Client::ConfigurationError';

export const I18N_AVAILABLE_AGENTS_DROPDOWN = {
  selectAgent: s__('ClusterAgents|Select an agent'),
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
          'ClusterAgents|The agent has not been connected in a long time. There might be a connectivity issue. Last contact was %{timeAgo}.',
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
    'ClusterIntegration|Use the %{linkStart}GitLab Agent%{linkEnd} to safely connect your Kubernetes clusters to GitLab. You can deploy your applications, run your pipelines, use Review Apps, and much more.',
  ),
  buttonText: s__('ClusterAgents|Connect with the GitLab Agent'),
};

export const I18N_CLUSTERS_EMPTY_STATE = {
  introText: s__(
    'ClusterIntegration|Connect your cluster to GitLab through %{linkStart}cluster certificates%{linkEnd}.',
  ),
  buttonText: s__('ClusterIntegration|Connect with a certificate'),
  alertText: s__(
    'ClusterIntegration|The certificate-based method to connect clusters to GitLab was %{linkStart}deprecated%{linkEnd} in GitLab 14.5.',
  ),
};

export const AGENT_CARD_INFO = {
  tabName: 'agent',
  title: sprintf(s__('ClusterAgents|%{number} of %{total} Agents')),
  emptyTitle: s__('ClusterAgents|No Agents'),
  tooltip: {
    label: s__('ClusterAgents|Recommended'),
    title: s__('ClusterAgents|GitLab Agent'),
    text: sprintf(
      s__(
        'ClusterAgents|The GitLab Agent provides an increased level of security when connecting Kubernetes clusters to GitLab. %{linkStart}Learn more about the GitLab Agent.%{linkEnd}',
      ),
    ),
    link: helpPagePath('user/clusters/agent/index'),
  },
  actionText: s__('ClusterAgents|Install new Agent'),
  footerText: sprintf(s__('ClusterAgents|View all %{number} agents')),
  installAgentDisabledHint: s__(
    'ClusterAgents|Requires a Maintainer or greater role to install new agents',
  ),
};

export const CERTIFICATE_BASED_CARD_INFO = {
  tabName: 'certificate_based',
  title: sprintf(
    s__('ClusterAgents|%{number} of %{total} clusters connected through cluster certificates'),
  ),
  emptyTitle: s__('ClusterAgents|No clusters connected through cluster certificates'),
  actionText: s__('ClusterAgents|Connect existing cluster'),
  footerText: sprintf(s__('ClusterAgents|View all %{number} clusters')),
  badgeText: s__('ClusterAgents|Deprecated'),
  connectExistingClusterDisabledHint: s__(
    'ClusterAgents|Requires a maintainer or greater role to connect existing clusters',
  ),
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
    title: s__('ClusterAgents|Certificate'),
    component: 'clusters',
    queryParamValue: 'certificate_based',
  },
];

export const CLUSTERS_ACTIONS = {
  actionsButton: s__('ClusterAgents|Actions'),
  createNewCluster: s__('ClusterAgents|Create a new cluster'),
  connectWithAgent: s__('ClusterAgents|Connect with agent'),
  connectExistingCluster: s__('ClusterAgents|Connect with a certificate'),
  agent: s__('ClusterAgents|Agent'),
  certificate: s__('ClusterAgents|Certificate'),
  dropdownDisabledHint: s__(
    'ClusterAgents|Requires a Maintainer or greater role to perform these actions',
  ),
};

export const DELETE_AGENT_BUTTON = {
  deleteButton: s__('ClusterAgents|Delete agent'),
  disabledHint: s__('ClusterAgents|Requires a Maintainer or greater role to delete agents'),
  modalTitle: __('Are you sure?'),
  modalBody: s__('ClusterAgents|Are you sure you want to delete this agent? You cannot undo this.'),
  modalInputLabel: s__('ClusterAgents|To delete the agent, type %{name} to confirm:'),
  modalAction: s__('ClusterAgents|Delete'),
  modalCancel: __('Cancel'),
  successMessage: s__('ClusterAgents|%{name} successfully deleted'),
  defaultError: __('An error occurred. Please try again.'),
};

export const AGENT = 'agent';
export const CERTIFICATE_BASED = 'certificate_based';

export const EVENT_LABEL_MODAL = 'agent_registration_modal';
export const EVENT_LABEL_TABS = 'kubernetes_section_tabs';
export const EVENT_ACTIONS_OPEN = 'open_modal';
export const EVENT_ACTIONS_SELECT = 'select_agent';
export const EVENT_ACTIONS_CLICK = 'click_button';
export const EVENT_ACTIONS_CHANGE = 'change_tab';

export const MODAL_TYPE_EMPTY = 'empty_state';
export const MODAL_TYPE_REGISTER = 'agent_registration';

export const DELETE_AGENT_MODAL_ID = 'delete-agent-modal-%{agentName}';

export const AGENT_FEEDBACK_ISSUE = 'https://gitlab.com/gitlab-org/gitlab/-/issues/342696';
export const AGENT_FEEDBACK_KEY = 'agent_feedback_banner';
