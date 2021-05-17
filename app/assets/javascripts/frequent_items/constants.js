import { s__ } from '~/locale';

export const FREQUENT_ITEMS = {
  MAX_COUNT: 20,
  LIST_COUNT_DESKTOP: 5,
  LIST_COUNT_MOBILE: 3,
  ELIGIBLE_FREQUENCY: 3,
};

export const HOUR_IN_MS = 3600000;

export const STORAGE_KEY = {
  projects: 'frequent-projects',
  groups: 'frequent-groups',
};

export const TRANSLATION_KEYS = {
  projects: {
    loadingMessage: s__('ProjectsDropdown|Loading projects'),
    header: s__('ProjectsDropdown|Frequently visited'),
    itemListErrorMessage: s__(
      'ProjectsDropdown|This feature requires browser localStorage support',
    ),
    itemListEmptyMessage: s__('ProjectsDropdown|Projects you visit often will appear here'),
    searchListErrorMessage: s__('ProjectsDropdown|Something went wrong on our end.'),
    searchListEmptyMessage: s__('ProjectsDropdown|Sorry, no projects matched your search'),
    searchInputPlaceholder: s__('ProjectsDropdown|Search your projects'),
  },
  groups: {
    loadingMessage: s__('GroupsDropdown|Loading groups'),
    header: s__('GroupsDropdown|Frequently visited'),
    itemListErrorMessage: s__('GroupsDropdown|This feature requires browser localStorage support'),
    itemListEmptyMessage: s__('GroupsDropdown|Groups you visit often will appear here'),
    searchListErrorMessage: s__('GroupsDropdown|Something went wrong on our end.'),
    searchListEmptyMessage: s__('GroupsDropdown|Sorry, no groups matched your search'),
    searchInputPlaceholder: s__('GroupsDropdown|Search your groups'),
  },
};

export const FREQUENT_ITEMS_PROJECTS = {
  namespace: 'projects',
  key: 'project',
  vuexModule: 'frequentProjects',
};

export const FREQUENT_ITEMS_GROUPS = {
  namespace: 'groups',
  key: 'group',
  vuexModule: 'frequentGroups',
};

export const FREQUENT_ITEMS_DROPDOWNS = [FREQUENT_ITEMS_PROJECTS, FREQUENT_ITEMS_GROUPS];
