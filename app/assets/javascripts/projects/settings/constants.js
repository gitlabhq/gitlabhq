import { __ } from '~/locale';

export const LEVEL_TYPES = {
  ROLE: 'role',
  USER: 'user',
  DEPLOY_KEY: 'deploy_key',
  GROUP: 'group',
};

export const ACCESS_LEVELS = {
  MERGE: 'merge_access_levels',
  PUSH: 'push_access_levels',
  CREATE: 'create_access_levels',
};

export const ACCESS_LEVEL_NONE = 0;

export const IDENTITY_VERIFICATION_REQUIRED_ERROR = __(
  'Shared runners enabled cannot be enabled until identity verification is completed',
);
