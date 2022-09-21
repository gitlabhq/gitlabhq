<script>
import createFlash from '~/flash';
import { __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import getProjectEnvironments from '../graphql/queries/project_environments.query.graphql';
import getProjectVariables from '../graphql/queries/project_variables.query.graphql';
import { mapEnvironmentNames, reportMessageToSentry } from '../utils';
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
import CiVariableSettings from './ci_variable_settings.vue';

export default {
  components: {
    CiVariableSettings,
  },
  inject: ['endpoint', 'projectFullPath', 'projectId'],
  data() {
    return {
      hasNextPage: false,
      isLoadingMoreItems: false,
      loadingCounter: 0,
      pageInfo: {},
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
          after: null,
          fullPath: this.projectFullPath,
        };
      },
      update(data) {
        return data?.project?.ciVariables?.nodes || [];
      },
      result({ data }) {
        this.pageInfo = data?.project?.ciVariables?.pageInfo || this.pageInfo;
        this.hasNextPage = this.pageInfo?.hasNextPage || false;
        // Because graphQL has a limit of 100 items,
        // we batch load all the variables by making successive queries
        // to keep the same UX. As a safeguard, we make sure that we cannot go over
        // 20 consecutive API calls, which means 2000 variables loaded maximum.
        if (!this.hasNextPage) {
          this.isLoadingMoreItems = false;
        } else if (this.loadingCounter < 20) {
          this.hasNextPage = false;
          this.fetchMoreVariables();
          this.loadingCounter += 1;
        } else {
          createFlash({ message: this.$options.tooManyCallsError });
          reportMessageToSentry(this.$options.componentName, this.$options.tooManyCallsError, {});
        }
      },
      error() {
        this.isLoadingMoreItems = false;
        this.hasNextPage = false;
        createFlash({ message: variableFetchErrorText });
      },
    },
  },
  computed: {
    isLoading() {
      return (
        this.$apollo.queries.projectVariables.loading ||
        this.$apollo.queries.projectEnvironments.loading ||
        this.isLoadingMoreItems
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
    fetchMoreVariables() {
      this.isLoadingMoreItems = true;

      this.$apollo.queries.projectVariables.fetchMore({
        variables: {
          fullPath: this.projectFullPath,
          after: this.pageInfo.endCursor,
        },
      });
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
        if (data[currentMutation.name]?.errors?.length) {
          const { errors } = data[currentMutation.name];
          createFlash({ message: errors[0] });
        }
      } catch {
        createFlash({ message: genericMutationErrorText });
      }
    },
  },
  componentName: 'ProjectVariables',
  i18n: {
    tooManyCallsError: __('Maximum number of variables loaded (2000)'),
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
