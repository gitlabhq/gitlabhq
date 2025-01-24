import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const MAX_LIST_COUNT = 25;

export const EVENTS_STORED_DAYS = 7;

export const EVENT_DETAILS = {
  token_created: {
    eventTypeIcon: 'token',
    title: s__('ClusterAgents|%{tokenName} created'),
    body: s__('ClusterAgents|Token created by %{userName}'),
  },
  token_revoked: {
    eventTypeIcon: 'token',
    title: s__('ClusterAgents|%{tokenName} revoked'),
    body: s__('ClusterAgents|Token revoked by %{userName}'),
  },
  agent_connected: {
    eventTypeIcon: 'connected',
    title: s__('ClusterAgents|%{titleIcon}Connected'),
    body: s__('ClusterAgents|Agent %{strongStart}connected%{strongEnd}'),
    titleIcon: {
      name: 'status-success',
      class: 'gl-text-success',
    },
  },
  agent_disconnected: {
    eventTypeIcon: 'connected',
    title: s__('ClusterAgents|%{titleIcon}Not connected'),
    body: s__('ClusterAgents|Agent %{strongStart}disconnected%{strongEnd}'),
    titleIcon: {
      name: 'severity-critical',
      class: 'gl-text-danger',
    },
  },
};

export const DEFAULT_ICON = 'token';

export const CREATE_TOKEN_MODAL = 'create-token';
export const EVENT_LABEL_MODAL = 'agent_token_creation_modal';
export const EVENT_ACTIONS_OPEN = 'open_modal';
export const EVENT_ACTIONS_CLICK = 'click_button';

export const TOKEN_NAME_LIMIT = 255;

export const REVOKE_TOKEN_MODAL_ID = 'revoke-token-%{tokenName}';

export const INTEGRATION_STATUS_VALID_TOKEN = {
  icon: 'status-success',
  iconClass: 'gl-text-success',
  text: s__('ClusterAgents|Valid access token'),
};
export const INTEGRATION_STATUS_NO_TOKEN = {
  icon: 'status-alert',
  iconClass: 'gl-text-red-500',
  text: s__('ClusterAgents|No agent access token'),
};

export const INTEGRATION_STATUS_RESTRICTED_CI_CD = {
  icon: 'information',
  iconClass: 'text-info',
  text: s__('ClusterAgents|CI/CD workflow with restricted access'),
  helpUrl: helpPagePath('user/clusters/agent/ci_cd_workflow', {
    anchor: 'restrict-project-and-group-access-by-using-impersonation',
  }),
  featureName: 'clusterAgentsCiImpersonation',
};
