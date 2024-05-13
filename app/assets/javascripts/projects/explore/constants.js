import { __ } from '~/locale';

export const SORT_OPTION_NAME = {
  value: 'name',
  text: __('Name'),
};

export const SORT_OPTION_CREATED = {
  value: 'created',
  text: __('Created'),
};

export const SORT_OPTION_UPDATED = {
  value: 'latest_activity',
  text: __('Updated'),
};

export const SORT_OPTION_STARS = {
  value: 'stars',
  text: __('Stars'),
};

export const SORT_DIRECTION_ASC = 'asc';
export const SORT_DIRECTION_DESC = 'desc';

export const FILTERED_SEARCH_TERM_KEY = 'name';
export const FILTERED_SEARCH_NAMESPACE = 'explore';
export const SORT_OPTIONS = [
  SORT_OPTION_NAME,
  SORT_OPTION_CREATED,
  SORT_OPTION_UPDATED,
  SORT_OPTION_STARS,
];
