import { __ } from '~/locale';

export const LEVEL_TYPES = {
  ROLE: 'role',
  USER: 'user',
  DEPLOY_KEY: 'deploy_key',
  GROUP: 'group',
  // Must match the backend `humanize_member_role` type string (`:member_role`)
  MEMBER_ROLE: 'member_role',
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
