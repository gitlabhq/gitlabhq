import { __, s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const MAX_LIST_COUNT = 20;
export const INSTALL_AGENT_MODAL_ID = 'install-agent';
export const ACTIVE_CONNECTION_TIME = 480000;
export const NAME_MAX_LENGTH = 50;

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
  default: { className: 'gl-bg-white', title: __('Unknown') },
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
    "ClusterAgents|The agent version do not match each other across your cluster's pods. This can happen when a new agent version was just deployed and Kubernetes is shutting down the old pods.",
  ),
  versionWarningsTitle: s__('ClusterAgents|Agent version update required'),
  versionWarningsMismatchTitle: s__('ClusterAgents|Agent version mismatch and update'),
  viewDocsText: s__('ClusterAgents|How do I update an agent?'),
  defaultConfigText: s__('ClusterAgents|Default configuration'),
  defaultConfigTooltip: s__('ClusterAgents|What is default configuration?'),
  sharedBadgeText: s__('ClusterAgents|Shared'),
  receptiveBadgeText: s__('ClusterAgents|Receptive'),
  externalConfigText: s__('ClusterAgents|External project'),
};

export const I18N_AGENT_TOKEN = {
  copyToken: s__('ClusterAgents|Copy token'),
  copyCommand: s__('ClusterAgents|Copy command'),
  tokenLabel: s__('ClusterAgents|Agent access token:'),
  tokenSingleUseWarningTitle: s__(
    'ClusterAgents|You cannot see this token again after you close this window.',
  ),
  tokenSubtitle: s__('ClusterAgents|The agent uses the token to connect with GitLab.'),

  basicInstallTitle: s__('ClusterAgents|Install using Helm (recommended)'),
  basicInstallBody: s__(
    'ClusterAgents|From a terminal, connect to your cluster and run this command. The token is included in the command.',
  ),
  helmVersionText: s__(
    'ClusterAgents|Use a Helm version compatible with your Kubernetes version (see %{linkStart}Helm version support policy%{linkEnd}).',
  ),

  advancedInstallTitle: s__('ClusterAgents|Advanced installation methods'),
  advancedInstallBody: s__(
    'ClusterAgents|%{linkStart}View the documentation%{linkEnd} for advanced installation. Ensure you have your access token available.',
  ),
};

export const HELM_VERSION_POLICY_URL = 'https://helm.sh/docs/topics/version_skew/';

export const I18N_AGENT_MODAL = {
  registerAgentButton: s__('ClusterAgents|Create and register'),
  close: __('Close'),
  cancel: __('Cancel'),
  learMore: __('Learn more.'),

  modalTitle: s__('ClusterAgents|Connect a Kubernetes cluster'),
  modalBody: s__('ClusterAgents|Create a new agent to register with GitLab.'),
  enableKasText: s__(
    "ClusterAgents|Your instance doesn't have the %{linkStart}GitLab Agent Server (KAS)%{linkEnd} set up. Ask a GitLab Administrator to install it.",
  ),
  altText: s__('ClusterAgents|GitLab agent for Kubernetes'),
  registrationSuccess: s__('ClusterAgents|%{agentName} successfully created.'),
  registrationErrorTitle: s__('ClusterAgents|Failed to register an agent'),
  unknownError: s__('ClusterAgents|An unknown error occurred. Please try again.'),
  registerWithUITitle: s__('ClusterAgents|Option 2: Create and register an agent with the UI'),
  bootstrapWithFluxTitle: s__('ClusterAgents|Option 1: Bootstrap the agent with Flux'),
  bootstrapWithFluxDescription: s__(
    'ClusterAgents|If Flux is installed in the cluster, you can install and register the agent from the command line:',
  ),
  bootstrapWithFluxOptions: s__(
    'ClusterAgents|You can view a list of options with %{codeStart}--help%{codeEnd}.',
  ),
  bootstrapWithFluxDocs: s__(
    "ClusterAgents|If you're %{linkStart}bootstrapping the agent with Flux%{linkEnd}, you can close this dialog.",
  ),
  agentNamePlaceholder: s__('ClusterAgents|Name of new agent'),
  requiredFieldFeedback: s__('ClusterAgents|This field is required.'),
};

export const KAS_DISABLED_ERROR = 'Gitlab::Kas::Client::ConfigurationError';

export const AGENT_STATUSES = {
  active: {
    name: s__('ClusterAgents|Connected'),
    icon: 'status-success',
    class: 'gl-text-success',
    tooltip: {
      title: sprintf(s__('ClusterAgents|Last connected %{timeAgo}.')),
    },
  },
  inactive: {
    name: s__('ClusterAgents|Not connected'),
    icon: 'status-alert',
    class: 'gl-text-red-500',
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
    class: 'gl-text-subtle',
    tooltip: {
      title: s__('ClusterAgents|Agent never connected to GitLab'),
      body: s__('ClusterAgents|Make sure you are using a valid token.'),
    },
  },
};

export const I18N_AGENTS_EMPTY_STATE = {
  title: s__("ClusterIntegration|Your project doesn't have any GitLab agents"),
  introText: s__(
    'ClusterIntegration|Use the %{linkStart}GitLab agent%{linkEnd} to safely connect your Kubernetes clusters to GitLab. You can deploy your applications, run your pipelines, use Review Apps, and much more.',
  ),
};

export const I18N_CLUSTERS_EMPTY_STATE = {
  introText: s__(
    'ClusterIntegration|Connect your cluster to GitLab through %{linkStart}cluster certificates%{linkEnd}.',
  ),
  alertText: s__(
    'ClusterIntegration|The certificate-based method to connect clusters to GitLab was %{linkStart}deprecated%{linkEnd} in GitLab 14.5.',
  ),
};

export const AGENT_CARD_INFO = {
  tabName: 'agent',
  title: sprintf(s__('ClusterAgents|%{number} of %{total} agents')),
  emptyTitle: s__('ClusterAgents|No agents'),
  tooltip: {
    label: s__('ClusterAgents|Recommended'),
    title: s__('ClusterAgents|GitLab agent'),
    text: sprintf(
      s__(
        'ClusterAgents|The GitLab agent provides an increased level of security when connecting Kubernetes clusters to GitLab. %{linkStart}Learn more about the GitLab agent.%{linkEnd}',
      ),
    ),
    link: helpPagePath('user/clusters/agent/_index'),
  },
  footerText: sprintf(s__('ClusterAgents|View all %{number} agents')),
};

export const CERTIFICATE_BASED_CARD_INFO = {
  tabName: 'certificate_based',
  title: sprintf(
    s__('ClusterAgents|%{number} of %{total} clusters connected through cluster certificates'),
  ),
  emptyTitle: s__('ClusterAgents|No clusters connected through cluster certificates'),
  footerText: sprintf(s__('ClusterAgents|View all %{number} clusters')),
  badgeText: s__('ClusterAgents|Deprecated'),
};

export const MAX_CLUSTERS_LIST = 6;

export const ALL_TAB = {
  title: s__('ClusterAgents|All'),
  component: 'ClustersViewAll',
  queryParamValue: 'all',
};

export const AGENT_TAB = {
  title: s__('ClusterAgents|Agent'),
  component: 'agents',
  queryParamValue: 'agent',
};
export const CERTIFICATE_TAB = {
  title: s__('ClusterAgents|Certificate'),
  component: 'clusters',
  queryParamValue: 'certificate_based',
};

export const CLUSTERS_TABS = [ALL_TAB, AGENT_TAB, CERTIFICATE_TAB];

export const CLUSTERS_ACTIONS = {
  connectCluster: s__('ClusterAgents|Connect a cluster'),
  connectWithAgent: s__('ClusterAgents|Connect a cluster (agent)'),
  connectClusterDeprecated: s__('ClusterAgents|Connect a cluster (deprecated)'),
  createCluster: s__('ClusterAgents|Create a cluster'),
  connectClusterCertificate: s__('ClusterAgents|Connect a cluster (certificate - deprecated)'),
  actionsDisabledHint: s__(
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
export const EVENT_ACTIONS_CLICK = 'click_button';
export const EVENT_ACTIONS_CHANGE = 'change_tab';

export const MODAL_TYPE_EMPTY = 'empty_state';
export const MODAL_TYPE_REGISTER = 'agent_registration';

export const DELETE_AGENT_MODAL_ID = 'delete-agent-modal-%{agentName}';

export const AGENT_FEEDBACK_ISSUE = 'https://gitlab.com/gitlab-org/gitlab/-/issues/342696';
export const AGENT_FEEDBACK_KEY = 'agent_feedback_banner';

export const CONNECT_MODAL_ID = 'connect-to-cluster-modal';

export const MAX_CONFIGS_SHOWN = 100;
