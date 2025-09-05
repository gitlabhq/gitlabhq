import { __ } from '~/locale';
import {
  SORT_LABEL_NAME,
  SORT_LABEL_CREATED,
  SORT_LABEL_UPDATED,
  PAGINATION_TYPE_OFFSET,
} from '~/groups_projects/constants';
import NestedGroupsProjectsList from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list.vue';
import { formatGraphQLGroupsAndProjects } from '~/vue_shared/components/nested_groups_projects_list/formatter';
import subgroupsAndProjectsQuery from './graphql/queries/subgroups_and_projects.query.graphql';

const subgroupsAndProjectsFormatter = (items) =>
  formatGraphQLGroupsAndProjects(
    items,
    (group) => ({
      editPath: group.editPath,
      avatarLabel: group.name,
    }),
    (project) => ({
      editPath: project.editPath,
      avatarLabel: project.name,
    }),
  );

const baseTab = {
  query: subgroupsAndProjectsQuery,
  queryPath: 'subgroupsAndProjects',
  paginationType: PAGINATION_TYPE_OFFSET,
  formatter: subgroupsAndProjectsFormatter,
  listComponent: NestedGroupsProjectsList,
  queryErrorMessage: __(
    "Your subgroups and projects couldn't be loaded. Refresh the page to try again.",
  ),
};

export const SUBGROUPS_AND_PROJECTS_TAB = {
  ...baseTab,
  variables: { active: true },
  text: __('Subgroups and projects'),
  value: 'subgroups_and_projects',
};

export const INACTIVE_TAB = {
  ...baseTab,
  variables: { active: false },
  text: __('Inactive'),
  value: 'inactive',
};

export const SORT_OPTION_NAME = {
  value: 'name',
  text: SORT_LABEL_NAME,
};

export const SORT_OPTION_CREATED = {
  value: 'created_at',
  text: SORT_LABEL_CREATED,
};

export const SORT_OPTION_UPDATED = {
  value: 'updated_at',
  text: SORT_LABEL_UPDATED,
};

export const SORT_OPTIONS = [SORT_OPTION_NAME, SORT_OPTION_CREATED, SORT_OPTION_UPDATED];

export const GROUPS_SHOW_TABS = [SUBGROUPS_AND_PROJECTS_TAB, INACTIVE_TAB];

export const BASE_ROUTE = '/(groups)?/:group*';

export const FILTERED_SEARCH_TERM_KEY = 'filter';
export const FILTERED_SEARCH_NAMESPACE = 'groups-show';
