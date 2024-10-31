import { __ } from '~/locale';

export const FILTERED_SEARCH_NAMESPACE = 'admin-groups';
export const FILTERED_SEARCH_TERM_KEY = 'name';

export const SORT_DIRECTION_ASC = 'asc';
export const SORT_DIRECTION_DESC = 'desc';

const NAME = 'name';
const CREATED = 'created';
const LATEST_ACTIVITY = 'latest_activity';
const STORAGE_SIZE = 'storage_size';

export const SORT_OPTION_NAME = {
  text: __('Name'),
  value: NAME,
};

export const SORT_OPTION_CREATED_DATE = {
  text: __('Created date'),
  value: CREATED,
};

export const SORT_OPTION_UPDATED_DATE = {
  text: __('Updated date'),
  value: LATEST_ACTIVITY,
};

export const SORT_OPTION_STORAGE_SIZE = {
  text: __('Storage size'),
  value: STORAGE_SIZE,
};

export const SORT_OPTIONS = [
  SORT_OPTION_NAME,
  SORT_OPTION_CREATED_DATE,
  SORT_OPTION_UPDATED_DATE,
  SORT_OPTION_STORAGE_SIZE,
];
