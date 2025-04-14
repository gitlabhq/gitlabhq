import {
  SORT_LABEL_NAME,
  SORT_LABEL_CREATED,
  SORT_LABEL_UPDATED,
  SORT_LABEL_STARS,
} from '~/groups_projects/constants';

export const SORT_OPTION_NAME = {
  value: 'name',
  text: SORT_LABEL_NAME,
};

export const SORT_OPTION_CREATED = {
  value: 'created',
  text: SORT_LABEL_CREATED,
};

export const SORT_OPTION_UPDATED = {
  value: 'latest_activity',
  text: SORT_LABEL_UPDATED,
};

export const SORT_OPTION_STARS = {
  value: 'stars',
  text: SORT_LABEL_STARS,
};

export const FILTERED_SEARCH_TERM_KEY = 'name';
export const FILTERED_SEARCH_NAMESPACE = 'explore';
export const SORT_OPTIONS = [
  SORT_OPTION_NAME,
  SORT_OPTION_CREATED,
  SORT_OPTION_UPDATED,
  SORT_OPTION_STARS,
];
