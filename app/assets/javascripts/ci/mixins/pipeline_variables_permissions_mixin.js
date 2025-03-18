import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import getPipelineVariablesMinimumOverrideRoleQuery from '~/ci/pipeline_variables_minimum_override_role/graphql/queries/get_pipeline_variables_minimum_override_role_project_setting.query.graphql';

const ROLE_NO_ONE = 'no_one_allowed';
const ROLE_DEVELOPER = 'developer';
const ROLE_MAINTAINER = 'maintainer';
const ROLE_OWNER = 'owner';

export default {
  USER_ROLES: Object.freeze([ROLE_DEVELOPER, ROLE_MAINTAINER, ROLE_OWNER]),

  inject: ['projectPath', 'userRole'],

  data() {
    return {
      hasError: false,
      pipelineVariablesSettings: {},
    };
  },

  apollo: {
    pipelineVariablesSettings: {
      query: getPipelineVariablesMinimumOverrideRoleQuery,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      update({ project }) {
        return project?.ciCdSettings || {};
      },
      error() {
        this.hasError = true;
        createAlert({
          message: s__('CiVariables|There was a problem fetching the CI/CD settings.'),
        });
      },
    },
  },

  computed: {
    pipelineVariablesPermissionsLoading() {
      return this.$apollo.queries.pipelineVariablesSettings.loading;
    },
    minimumRole() {
      return this.pipelineVariablesSettings?.pipelineVariablesMinimumOverrideRole;
    },
    canViewPipelineVariables() {
      if (this.pipelineVariablesPermissionsLoading) return false;

      if (this.minimumRole === ROLE_NO_ONE || this.hasError) {
        return false;
      }

      const userRoleIndex = this.$options.USER_ROLES.indexOf(this.userRole?.toLowerCase());
      const minRoleIndex = this.$options.USER_ROLES.indexOf(this.minimumRole);

      return userRoleIndex >= minRoleIndex || false;
    },
  },
};
