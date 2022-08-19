<script>
import createFlash from '~/flash';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import getProjectEnvironments from '../graphql/queries/project_environments.query.graphql';
import getProjectVariables from '../graphql/queries/project_variables.query.graphql';
import { mapEnvironmentNames } from '../utils';
import {
  ADD_MUTATION_ACTION,
  DELETE_MUTATION_ACTION,
  GRAPHQL_PROJECT_TYPE,
  UPDATE_MUTATION_ACTION,
  environmentFetchErrorText,
  genericMutationErrorText,
  variableFetchErrorText,
} from '../constants';
import addProjectVariable from '../graphql/mutations/project_add_variable.mutation.graphql';
import deleteProjectVariable from '../graphql/mutations/project_delete_variable.mutation.graphql';
import updateProjectVariable from '../graphql/mutations/project_update_variable.mutation.graphql';
import ciVariableSettings from './ci_variable_settings.vue';

export default {
  components: {
    ciVariableSettings,
  },
  inject: ['endpoint', 'projectFullPath', 'projectId'],
  data() {
    return {
      projectEnvironments: [],
      projectVariables: [],
    };
  },
  apollo: {
    projectEnvironments: {
      query: getProjectEnvironments,
      variables() {
        return {
          fullPath: this.projectFullPath,
        };
      },
      update(data) {
        return mapEnvironmentNames(data?.project?.environments?.nodes);
      },
      error() {
        createFlash({ message: environmentFetchErrorText });
      },
    },
    projectVariables: {
      query: getProjectVariables,
      variables() {
        return {
          fullPath: this.projectFullPath,
        };
      },
      update(data) {
        return data?.project?.ciVariables?.nodes || [];
      },
      error() {
        createFlash({ message: variableFetchErrorText });
      },
    },
  },
  computed: {
    isLoading() {
      return (
        this.$apollo.queries.projectVariables.loading ||
        this.$apollo.queries.projectEnvironments.loading
      );
    },
  },
  methods: {
    addVariable(variable) {
      this.variableMutation(ADD_MUTATION_ACTION, variable);
    },
    deleteVariable(variable) {
      this.variableMutation(DELETE_MUTATION_ACTION, variable);
    },
    updateVariable(variable) {
      this.variableMutation(UPDATE_MUTATION_ACTION, variable);
    },
    async variableMutation(mutationAction, variable) {
      try {
        const currentMutation = this.$options.mutationData[mutationAction];
        const { data } = await this.$apollo.mutate({
          mutation: currentMutation.action,
          variables: {
            endpoint: this.endpoint,
            fullPath: this.projectFullPath,
            projectId: convertToGraphQLId(GRAPHQL_PROJECT_TYPE, this.projectId),
            variable,
          },
        });

        const { errors } = data[currentMutation.name];
        if (errors.length > 0) {
          createFlash({ message: errors[0] });
        }
      } catch (e) {
        createFlash({ message: genericMutationErrorText });
      }
    },
  },
  mutationData: {
    [ADD_MUTATION_ACTION]: { action: addProjectVariable, name: 'addProjectVariable' },
    [UPDATE_MUTATION_ACTION]: { action: updateProjectVariable, name: 'updateProjectVariable' },
    [DELETE_MUTATION_ACTION]: { action: deleteProjectVariable, name: 'deleteProjectVariable' },
  },
};
</script>

<template>
  <ci-variable-settings
    :are-scoped-variables-available="true"
    :environments="projectEnvironments"
    :is-loading="isLoading"
    :variables="projectVariables"
    @add-variable="addVariable"
    @delete-variable="deleteVariable"
    @update-variable="updateVariable"
  />
</template>
