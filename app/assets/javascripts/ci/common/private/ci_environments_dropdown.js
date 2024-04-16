import CiEnvironmentsDropdown from '~/ci/ci_environments_dropdown/ci_environments_dropdown.vue';

export default CiEnvironmentsDropdown;

export { getGroupEnvironments } from '~/ci/ci_environments_dropdown/graphql/queries/group_environments.query.graphql';
export { getProjectEnvironments } from '~/ci/ci_environments_dropdown/graphql/queries/project_environments.query.graphql';

export * from '~/ci/ci_environments_dropdown/constants';
export * from '~/ci/ci_environments_dropdown/utils';
