import { s__ } from '~/locale';

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
      class: 'text-success-500',
    },
  },
  agent_disconnected: {
    eventTypeIcon: 'connected',
    title: s__('ClusterAgents|%{titleIcon}Not connected'),
    body: s__('ClusterAgents|Agent %{strongStart}disconnected%{strongEnd}'),
    titleIcon: {
      name: 'severity-critical',
      class: 'text-danger-800',
    },
  },
};

export const DEFAULT_ICON = 'token';
export const TOKEN_STATUS_ACTIVE = 'ACTIVE';
