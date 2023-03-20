import { s__ } from '~/locale';

export const ROLLOUT_STRATEGY_ALL_USERS = 'default';
export const ROLLOUT_STRATEGY_PERCENT_ROLLOUT = 'gradualRolloutUserId';
export const ROLLOUT_STRATEGY_FLEXIBLE_ROLLOUT = 'flexibleRollout';
export const ROLLOUT_STRATEGY_USER_ID = 'userWithId';
export const ROLLOUT_STRATEGY_GITLAB_USER_LIST = 'gitlabUserList';

export const PERCENT_ROLLOUT_GROUP_ID = 'default';

export const ALL_ENVIRONMENTS_NAME = '*';

export const NEW_VERSION_FLAG = 'new_version_flag';
export const LEGACY_FLAG = 'legacy_flag';

export const EMPTY_PARAMETERS = { parameters: {}, userListId: undefined };

export const STRATEGY_SELECTIONS = [
  {
    value: ROLLOUT_STRATEGY_ALL_USERS,
    text: s__('FeatureFlags|All users'),
  },
  {
    value: ROLLOUT_STRATEGY_FLEXIBLE_ROLLOUT,
    text: s__('FeatureFlags|Percent rollout'),
  },
  {
    value: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
    text: s__('FeatureFlags|Percent of users'),
  },
  {
    value: ROLLOUT_STRATEGY_USER_ID,
    text: s__('FeatureFlags|User IDs'),
  },
  {
    value: ROLLOUT_STRATEGY_GITLAB_USER_LIST,
    text: s__('FeatureFlags|User List'),
  },
];
