import { formValidators } from '@gitlab/ui/dist/utils';
import { s__, __ } from '~/locale';

export const RESOURCE_TYPE_GROUPS = 'groups';
export const RESOURCE_TYPE_PROJECTS = 'projects';

export const ORGANIZATION_ROOT_ROUTE_NAME = 'root';

export const ACCESS_LEVEL_DEFAULT = 'default';
export const ACCESS_LEVEL_OWNER = 'owner';

// Matches `app/graphql/types/organizations/organization_user_access_level_enum.rb
export const ACCESS_LEVEL_DEFAULT_STRING = 'DEFAULT';
export const ACCESS_LEVEL_OWNER_STRING = 'OWNER';

export const ACCESS_LEVEL_LABEL = {
  [ACCESS_LEVEL_DEFAULT_STRING]: __('User'),
  [ACCESS_LEVEL_OWNER_STRING]: __('Owner'),
};

export const FORM_FIELD_NAME = 'name';
export const FORM_FIELD_ID = 'id';
export const FORM_FIELD_PATH = 'path';
export const FORM_FIELD_DESCRIPTION = 'description';
export const FORM_FIELD_AVATAR = 'avatar';
export const FORM_FIELD_VISIBILITY_LEVEL = 'visibilityLevel';

export const MAX_DESCRIPTION_COUNT = 1024;

export const FORM_FIELD_PATH_VALIDATORS = [
  formValidators.required(s__('Organization|Organization URL is required.')),
  formValidators.factory(
    s__('Organization|Organization URL is too short (minimum is 2 characters).'),
    (val) => val.length >= 2,
  ),
];

export const FORM_FIELD_DESCRIPTION_VALIDATORS = [
  formValidators.factory(
    s__('Organization|Organization description is too long (maximum is 1024 characters).'),
    (val) => val.length <= MAX_DESCRIPTION_COUNT,
  ),
];

export const SORT_DIRECTION_ASC = 'asc';
export const SORT_DIRECTION_DESC = 'desc';

export const SORT_NAME = 'name';
export const SORT_CREATED_AT = 'created_at';
export const SORT_UPDATED_AT = 'updated_at';

export const SORT_ITEM_NAME = {
  value: SORT_NAME,
  text: __('Name'),
};

export const SORT_ITEM_CREATED_AT = {
  value: SORT_CREATED_AT,
  text: __('Created'),
};

export const SORT_ITEM_UPDATED_AT = {
  value: SORT_UPDATED_AT,
  text: __('Updated'),
};
