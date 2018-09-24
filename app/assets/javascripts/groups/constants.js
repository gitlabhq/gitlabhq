import { __, s__ } from '../locale';

export const MAX_CHILDREN_COUNT = 20;

export const ACTIVE_TAB_SUBGROUPS_AND_PROJECTS = 'subgroups_and_projects';
export const ACTIVE_TAB_SHARED = 'shared';
export const ACTIVE_TAB_ARCHIVED = 'archived';

export const GROUPS_LIST_HOLDER_CLASS = '.js-groups-list-holder';
export const GROUPS_FILTER_FORM_CLASS = '.js-group-filter-form';
export const CONTENT_LIST_CLASS = '.content-list';

export const COMMON_STR = {
  FAILURE: __('An error occurred. Please try again.'),
  LEAVE_FORBIDDEN: s__(
    'GroupsTree|Failed to leave the group. Please make sure you are not the only owner.',
  ),
  LEAVE_BTN_TITLE: s__('GroupsTree|Leave this group'),
  EDIT_BTN_TITLE: s__('GroupsTree|Edit group'),
  GROUP_SEARCH_EMPTY: s__('GroupsTree|No groups matched your search'),
  GROUP_PROJECT_SEARCH_EMPTY: s__('GroupsTree|No groups or projects matched your search'),
};

export const ITEM_TYPE = {
  PROJECT: 'project',
  GROUP: 'group',
};

export const GROUP_VISIBILITY_TYPE = {
  public: __(
    'Public - The group and any public projects can be viewed without any authentication.',
  ),
  internal: __(
    'Internal - The group and any internal projects can be viewed by any logged in user.',
  ),
  private: __('Private - The group and its projects can only be viewed by members.'),
};

export const PROJECT_VISIBILITY_TYPE = {
  public: __('Public - The project can be accessed without any authentication.'),
  internal: __('Internal - The project can be accessed by any logged in user.'),
  private: __('Private - Project access must be granted explicitly to each user.'),
};

export const VISIBILITY_TYPE_ICON = {
  public: 'earth',
  internal: 'shield',
  private: 'lock',
};
