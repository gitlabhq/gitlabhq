import { stateFilterData } from '~/search/sidebar/constants/state_filter_data';
import { confidentialFilterData } from '~/search/sidebar/constants/confidential_filter_data';
import { languageFilterData } from '~/search/sidebar/components/language_filter/data';

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

export const ICON_MAP = {
  blobs: 'code',
  issues: 'issues',
  merge_requests: 'merge-request',
  commits: 'commit',
  notes: 'comments',
  milestones: 'tag',
  users: 'users',
  projects: 'project',
  wiki_blobs: 'overview',
};
