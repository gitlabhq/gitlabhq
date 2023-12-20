<script>
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getProjectEnvironments } from '~/ci/common/private/ci_environments_dropdown';
import { ADD_MUTATION_ACTION, DELETE_MUTATION_ACTION, UPDATE_MUTATION_ACTION } from '../constants';
import getProjectVariables from '../graphql/queries/project_variables.query.graphql';
import addProjectVariable from '../graphql/mutations/project_add_variable.mutation.graphql';
import deleteProjectVariable from '../graphql/mutations/project_delete_variable.mutation.graphql';
import updateProjectVariable from '../graphql/mutations/project_update_variable.mutation.graphql';
import CiVariableShared from './ci_variable_shared.vue';

export default {
  components: {
    CiVariableShared,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectFullPath', 'projectId'],
  computed: {
    graphqlId() {
      return convertToGraphQLId(TYPENAME_PROJECT, this.projectId);
    },
  },
  mutationData: {
    [ADD_MUTATION_ACTION]: addProjectVariable,
    [UPDATE_MUTATION_ACTION]: updateProjectVariable,
    [DELETE_MUTATION_ACTION]: deleteProjectVariable,
  },
  queryData: {
    ciVariables: {
      lookup: (data) => data?.project?.ciVariables,
      query: getProjectVariables,
    },
    environments: {
      lookup: (data) => data?.project?.environments,
      query: getProjectEnvironments,
    },
  },
};
</script>

<template>
  <ci-variable-shared
    :id="graphqlId"
    :are-scoped-variables-available="true"
    component-name="ProjectVariables"
    entity="project"
    :full-path="projectFullPath"
    :mutation-data="$options.mutationData"
    :query-data="$options.queryData"
  />
</template>
