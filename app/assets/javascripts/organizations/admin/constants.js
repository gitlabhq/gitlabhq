import { s__ } from '~/locale';

export const MAX_ORGANIZATION_USER_INVITES = 20;

export const MIN_SEARCH_LENGTH = 3;

export const ORGANIZATION_USER_TYPE_USER = 'USER';
export const ORGANIZATION_USER_TYPE_ADMIN = 'ADMIN';
export const ORGANIZATION_USER_TYPE_DEFAULT = ORGANIZATION_USER_TYPE_USER;

export const ORGANIZATION_USER_TYPE_OPTIONS = [
  { value: ORGANIZATION_USER_TYPE_USER, text: s__('Organization|User') },
  { value: ORGANIZATION_USER_TYPE_ADMIN, text: s__('Organization|Admin') },
];
