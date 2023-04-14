import { __, s__ } from '~/locale';

export const MAX_CHILDREN_COUNT = 20;

export const ACTIVE_TAB_SUBGROUPS_AND_PROJECTS = 'subgroups_and_projects';
export const ACTIVE_TAB_SHARED = 'shared';
export const ACTIVE_TAB_ARCHIVED = 'archived';

export const GROUPS_LIST_HOLDER_CLASS = '.js-groups-list-holder';
export const CONTENT_LIST_CLASS = '.groups-list';

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

export const OVERVIEW_TABS_SORTING_ITEMS = [
  {
    label: __('Name'),
    asc: 'name_asc',
    desc: 'name_desc',
  },
  {
    label: __('Created'),
    asc: 'created_asc',
    desc: 'created_desc',
  },
  {
    label: __('Updated'),
    asc: 'latest_activity_asc',
    desc: 'latest_activity_desc',
  },
  {
    label: __('Stars'),
    asc: 'stars_asc',
    desc: 'stars_desc',
  },
];
