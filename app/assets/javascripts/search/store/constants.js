import { stateFilterData } from '~/search/sidebar/constants/state_filter_data';
import { confidentialFilterData } from '~/search/sidebar/constants/confidential_filter_data';
import { languageFilterData } from '~/search/sidebar/constants/language_filter_data';

export const MAX_FREQUENT_ITEMS = 5;

export const MAX_FREQUENCY = 5;

export const GROUPS_LOCAL_STORAGE_KEY = 'global-search-frequent-groups';

export const PROJECTS_LOCAL_STORAGE_KEY = 'global-search-frequent-projects';

export const SIDEBAR_PARAMS = [
  stateFilterData.filterParam,
  confidentialFilterData.filterParam,
  languageFilterData.filterParam,
];

export const NUMBER_FORMATING_OPTIONS = { notation: 'compact', compactDisplay: 'short' };
