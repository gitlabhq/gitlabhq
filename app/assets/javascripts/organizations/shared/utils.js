import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';
import { formatGraphQLGroups } from '~/vue_shared/components/groups_list/formatter';
import { SORT_CREATED_AT, SORT_UPDATED_AT } from './constants';

export const formatGroups = (groups) =>
  formatGraphQLGroups(groups, (group) => ({ editPath: group.organizationEditPath }));

export const formatProjects = (projects) =>
  formatGraphQLProjects(projects, (project) => ({ editPath: project.organizationEditPath }));

export const timestampType = (sortName) => {
  const SORT_MAP = {
    [SORT_CREATED_AT]: TIMESTAMP_TYPE_CREATED_AT,
    [SORT_UPDATED_AT]: TIMESTAMP_TYPE_UPDATED_AT,
  };

  return SORT_MAP[sortName] || TIMESTAMP_TYPE_CREATED_AT;
};
