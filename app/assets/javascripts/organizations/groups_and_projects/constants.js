import { __ } from '~/locale';

export const DISPLAY_QUERY_GROUPS = 'groups';
export const DISPLAY_QUERY_PROJECTS = 'projects';

export const FILTERED_SEARCH_TERM_KEY = 'search';

export const DISPLAY_LISTBOX_ITEMS = [
  {
    value: DISPLAY_QUERY_GROUPS,
    text: __('Groups'),
  },
  {
    value: DISPLAY_QUERY_PROJECTS,
    text: __('Projects'),
  },
];

export const SORT_DIRECTION_ASC = 'asc';
export const SORT_DIRECTION_DESC = 'desc';

export const SORT_ITEM_CREATED = {
  name: 'created',
  text: __('Created'),
};

export const SORT_ITEMS = [SORT_ITEM_CREATED];
