import { __, s__ } from '~/locale';

export const RESET_LABEL = __('Reset');
export const QUERY_TOO_SHORT_MESSAGE = __('Enter at least three characters to search.');

// Groups
export const GROUP_TOGGLE_TEXT = __('Search for a group');
export const GROUP_HEADER_TEXT = __('Select a group');
export const FETCH_GROUPS_ERROR = __('Unable to fetch groups. Reload the page to try again.');
export const FETCH_GROUP_ERROR = __('Unable to fetch group. Reload the page to try again.');

// Projects
export const PROJECT_TOGGLE_TEXT = s__('ProjectSelect|Search for project');
export const PROJECT_HEADER_TEXT = s__('ProjectSelect|Select a project');
export const FETCH_PROJECTS_ERROR = __('Unable to fetch projects. Reload the page to try again.');
export const FETCH_PROJECT_ERROR = __('Unable to fetch project. Reload the page to try again.');

// Organizations
export const ORGANIZATION_TOGGLE_TEXT = s__('Organization|Search for an organization');
export const ORGANIZATION_HEADER_TEXT = s__('Organization|Select an organization');
export const FETCH_ORGANIZATIONS_ERROR = s__(
  'Organization|Unable to fetch organizations. Reload the page to try again.',
);
export const FETCH_ORGANIZATION_ERROR = s__(
  'Organization|Unable to fetch organizations. Reload the page to try again.',
);
