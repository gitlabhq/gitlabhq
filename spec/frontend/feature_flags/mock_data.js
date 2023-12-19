import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_FLEXIBLE_ROLLOUT,
  ROLLOUT_STRATEGY_GITLAB_USER_LIST,
  ROLLOUT_STRATEGY_USER_ID,
} from '~/feature_flags/constants';

export const featureFlag = {
  id: 1,
  active: true,
  created_at: '2018-12-12T22:07:31.401Z',
  updated_at: '2018-12-12T22:07:31.401Z',
  name: 'test flag',
  description: 'flag for tests',
  destroy_path: 'feature_flags/1',
  update_path: 'feature_flags/1',
  edit_path: 'feature_flags/1/edit',
  strategies: [
    {
      id: 9,
      name: ROLLOUT_STRATEGY_ALL_USERS,
      parameters: {},
      scopes: [{ id: 17, environment_scope: '*' }],
    },
    {
      id: 8,
      name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
      parameters: {},
      scopes: [{ id: 18, environment_scope: 'review/*' }],
    },
    {
      id: 7,
      name: ROLLOUT_STRATEGY_USER_ID,
      parameters: { userIds: '1,2,3,4' },
      scopes: [{ id: 19, environment_scope: 'production' }],
    },
  ],
};

export const getRequestData = {
  feature_flags: [featureFlag],
  count: {
    all: 1,
    disabled: 1,
    enabled: 0,
  },
};

export const rotateData = { token: 'oP6sCNRqtRHmpy1gw2-F' };

export const userList = {
  name: 'test_users',
  user_xids: 'user3,user4,user5',
  id: 2,
  iid: 2,
  project_id: 1,
  created_at: '2020-02-04T08:13:10.507Z',
  updated_at: '2020-02-05T08:14:10.507Z',
  path: '/path/to/user/list',
  edit_path: '/path/to/user/list/edit',
};

export const userListStrategy = {
  name: ROLLOUT_STRATEGY_GITLAB_USER_LIST,
  parameters: {},
  scopes: [],
  userList,
};

export const percentRolloutStrategy = {
  name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  parameters: { percentage: '50', groupId: 'default' },
  scopes: [],
};

export const flexibleRolloutStrategy = {
  name: ROLLOUT_STRATEGY_FLEXIBLE_ROLLOUT,
  parameters: { rollout: '50', groupId: 'default', stickiness: 'default' },
  scopes: [],
};

export const usersWithIdStrategy = {
  name: ROLLOUT_STRATEGY_USER_ID,
  parameters: { userIds: '1,2,3' },
  scopes: [],
};

export const allUsersStrategy = {
  name: ROLLOUT_STRATEGY_ALL_USERS,
  parameters: {},
  scopes: [],
};
