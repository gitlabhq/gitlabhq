import { __, s__ } from '~/locale';
import {
  VISIBILITY_LEVEL_PRIVATE_STRING,
  VISIBILITY_LEVEL_INTERNAL_STRING,
  VISIBILITY_LEVEL_PUBLIC_STRING,
} from '~/visibility_level/constants';

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

export const GROUP_VISIBILITY_TYPE = {
  [VISIBILITY_LEVEL_PUBLIC_STRING]: __(
    'Public - The group and any public projects can be viewed without any authentication.',
  ),
  [VISIBILITY_LEVEL_INTERNAL_STRING]: __(
    'Internal - The group and any internal projects can be viewed by any logged in user except external users.',
  ),
  [VISIBILITY_LEVEL_PRIVATE_STRING]: __(
    'Private - The group and its projects can only be viewed by members.',
  ),
};

export const PROJECT_VISIBILITY_TYPE = {
  [VISIBILITY_LEVEL_PUBLIC_STRING]: __(
    'Public - The project can be accessed without any authentication.',
  ),
  [VISIBILITY_LEVEL_INTERNAL_STRING]: __(
    'Internal - The project can be accessed by any logged in user except external users.',
  ),
  [VISIBILITY_LEVEL_PRIVATE_STRING]: __(
    'Private - Project access must be granted explicitly to each user. If this project is part of a group, access will be granted to members of the group.',
  ),
};

export const VISIBILITY_TYPE_ICON = {
  [VISIBILITY_LEVEL_PUBLIC_STRING]: 'earth',
  [VISIBILITY_LEVEL_INTERNAL_STRING]: 'shield',
  [VISIBILITY_LEVEL_PRIVATE_STRING]: 'lock',
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
