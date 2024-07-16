import { __, s__ } from '~/locale';

export const MAX_CHILDREN_COUNT = 20;

export const ACTIVE_TAB_SUBGROUPS_AND_PROJECTS = 'subgroups_and_projects';
export const ACTIVE_TAB_SHARED = 'shared';
export const ACTIVE_TAB_INACTIVE = 'inactive';

export const COMMON_STR = {
  FAILURE: __('An error occurred. Please try again.'),
  LEAVE_FORBIDDEN: s__(
    'GroupsTree|Failed to leave the group. Please make sure you are not the only owner.',
  ),
  LEAVE_BTN_TITLE: s__('GroupsTree|Leave group'),
  EDIT_BTN_TITLE: s__('GroupsTree|Edit'),
  REMOVE_BTN_TITLE: s__('GroupsTree|Delete'),
  OPTIONS_DROPDOWN_TITLE: s__('GroupsTree|Options'),
};

export const ITEM_TYPE = {
  PROJECT: 'project',
  GROUP: 'group',
};

export const SORTING_ITEM_NAME = {
  label: __('Name'),
  asc: 'name_asc',
  desc: 'name_desc',
};

export const SORTING_ITEM_CREATED = {
  label: __('Created date'),
  asc: 'created_asc',
  desc: 'created_desc',
};

export const SORTING_ITEM_UPDATED = {
  label: __('Updated date'),
  asc: 'latest_activity_asc',
  desc: 'latest_activity_desc',
};

export const SORTING_ITEM_STARS = {
  label: __('Stars'),
  asc: 'stars_asc',
  desc: 'stars_desc',
};

export const GROUPS_LIST_FILTERED_SEARCH_TERM_KEY = 'filter';
export const GROUPS_LIST_SORTING_ITEMS = [
  SORTING_ITEM_NAME,
  SORTING_ITEM_CREATED,
  SORTING_ITEM_UPDATED,
];

export const EXPLORE_FILTERED_SEARCH_NAMESPACE = 'explore';
export const DASHBOARD_FILTERED_SEARCH_NAMESPACE = 'dashboard';

export const OVERVIEW_TABS_FILTERED_SEARCH_TERM_KEY = 'filter';
export const OVERVIEW_TABS_FILTERED_SEARCH_NAMESPACE = 'overview';

export const OVERVIEW_TABS_SORTING_ITEMS = [
  SORTING_ITEM_NAME,
  SORTING_ITEM_CREATED,
  SORTING_ITEM_UPDATED,
  SORTING_ITEM_STARS,
];

export const OVERVIEW_TABS_ARCHIVED_PROJECTS_SORTING_ITEMS = [
  SORTING_ITEM_NAME,
  SORTING_ITEM_CREATED,
  SORTING_ITEM_UPDATED,
];

export const FORM_FIELD_NAME = 'name';
export const FORM_FIELD_PATH = 'path';
export const FORM_FIELD_ID = 'id';
export const FORM_FIELD_VISIBILITY_LEVEL = 'visibilityLevel';
