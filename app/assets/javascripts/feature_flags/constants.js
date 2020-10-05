import { property } from 'lodash';
import { s__ } from '~/locale';

export const ROLLOUT_STRATEGY_ALL_USERS = 'default';
export const ROLLOUT_STRATEGY_PERCENT_ROLLOUT = 'gradualRolloutUserId';
export const ROLLOUT_STRATEGY_USER_ID = 'userWithId';
export const ROLLOUT_STRATEGY_GITLAB_USER_LIST = 'gitlabUserList';

export const PERCENT_ROLLOUT_GROUP_ID = 'default';

export const DEFAULT_PERCENT_ROLLOUT = '100';

export const ALL_ENVIRONMENTS_NAME = '*';

export const INTERNAL_ID_PREFIX = 'internal_';

export const fetchPercentageParams = property(['parameters', 'percentage']);
export const fetchUserIdParams = property(['parameters', 'userIds']);

export const NEW_VERSION_FLAG = 'new_version_flag';
export const LEGACY_FLAG = 'legacy_flag';

export const NEW_FLAG_ALERT = s__(
  'FeatureFlags|Feature Flags will look different in the next milestone. No action is needed, but you may notice the functionality was changed to improve the workflow.',
);

export const FEATURE_FLAG_SCOPE = 'featureFlags';
export const USER_LIST_SCOPE = 'userLists';
