import { s__, n__, sprintf } from '~/locale';
import {
  ALL_ENVIRONMENTS_NAME,
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_FLEXIBLE_ROLLOUT,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
  ROLLOUT_STRATEGY_GITLAB_USER_LIST,
} from './constants';

const badgeTextByType = {
  [ROLLOUT_STRATEGY_ALL_USERS]: {
    name: s__('FeatureFlags|All Users'),
    parameters: null,
  },
  [ROLLOUT_STRATEGY_FLEXIBLE_ROLLOUT]: {
    name: s__('FeatureFlags|Percent rollout'),
    parameters: ({ parameters: { rollout, stickiness } }) => {
      switch (stickiness) {
        case 'USERID':
          return sprintf(s__('FeatureFlags|%{percent} by user ID'), { percent: `${rollout}%` });
        case 'SESSIONID':
          return sprintf(s__('FeatureFlags|%{percent} by session ID'), { percent: `${rollout}%` });
        case 'RANDOM':
          return sprintf(s__('FeatureFlags|%{percent} randomly'), { percent: `${rollout}%` });
        default:
          return sprintf(s__('FeatureFlags|%{percent} by available ID'), {
            percent: `${rollout}%`,
          });
      }
    },
  },
  [ROLLOUT_STRATEGY_PERCENT_ROLLOUT]: {
    name: s__('FeatureFlags|Percent of users'),
    parameters: ({ parameters: { percentage } }) => `${percentage}%`,
  },
  [ROLLOUT_STRATEGY_USER_ID]: {
    name: s__('FeatureFlags|User IDs'),
    parameters: ({ parameters: { userIds } }) =>
      sprintf(n__('FeatureFlags|%d user', 'FeatureFlags|%d users', userIds.split(',').length)),
  },
  [ROLLOUT_STRATEGY_GITLAB_USER_LIST]: {
    name: s__('FeatureFlags|User List'),
    parameters: ({ user_list: { name } }) => name,
  },
};

const scopeName = ({ environment_scope: scope }) =>
  scope === ALL_ENVIRONMENTS_NAME ? s__('FeatureFlags|All Environments') : scope;

export const labelForStrategy = (strategy) => {
  const { name, parameters } = badgeTextByType[strategy.name];
  const scopes = strategy.scopes.map(scopeName).join(', ');

  return {
    name,
    parameters: parameters ? parameters(strategy) : null,
    scopes,
  };
};
