import { __ } from '~/locale';

export const ANY_OPTION = Object.freeze({
  id: null,
  name: __('Any'),
  name_with_namespace: __('Any'),
});

export const GROUP_DATA = {
  headerText: __('Filter results by group'),
  queryParam: 'group_id',
  selectedDisplayValue: 'name',
  itemsDisplayValue: 'full_name',
};

export const PROJECT_DATA = {
  headerText: __('Filter results by project'),
  queryParam: 'project_id',
  selectedDisplayValue: 'name_with_namespace',
  itemsDisplayValue: 'name_with_namespace',
};

export const ALL_SCOPE_TABS = {
  blobs: { scope: 'blobs', title: __('Code'), qaSelector: 'code_tab' },
  issues: { scope: 'issues', title: __('Issues') },
  merge_requests: { scope: 'merge_requests', title: __('Merge requests') },
  milestones: { scope: 'milestones', title: __('Milestones') },
  notes: { scope: 'notes', title: __('Comments') },
  wiki_blobs: { scope: 'wiki_blobs', title: __('Wiki') },
  commits: { scope: 'commits', title: __('Commits') },
  epics: { scope: 'epics', title: __('Epics') },
  users: { scope: 'users', title: __('Users') },
  snippet_titles: { scope: 'snippet_titles', title: __('Titles and Descriptions') },
  projects: { scope: 'projects', title: __('Projects'), qaSelector: 'projects_tab' },
};
