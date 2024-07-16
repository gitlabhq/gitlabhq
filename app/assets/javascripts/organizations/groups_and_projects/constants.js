import { __ } from '~/locale';
import {
  SORT_ITEM_NAME,
  SORT_ITEM_CREATED_AT,
  SORT_ITEM_UPDATED_AT,
  SORT_NAME,
  SORT_CREATED_AT,
  SORT_UPDATED_AT,
} from '../shared/constants';

export const DISPLAY_QUERY_GROUPS = 'groups';
export const DISPLAY_QUERY_PROJECTS = 'projects';

export const FILTERED_SEARCH_TERM_KEY = 'search';
export const FILTERED_SEARCH_NAMESPACE = 'organization';

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

export const SORT_ITEMS = [SORT_ITEM_NAME, SORT_ITEM_CREATED_AT, SORT_ITEM_UPDATED_AT];

export const SORT_ITEMS_GRAPHQL_ENUMS = {
  [SORT_NAME]: 'NAME',
  [SORT_CREATED_AT]: 'CREATED',
  [SORT_UPDATED_AT]: 'UPDATED',
};
