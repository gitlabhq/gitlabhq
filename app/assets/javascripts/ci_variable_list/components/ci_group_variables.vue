<script>
import createFlash from '~/flash';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getGroupVariables from '../graphql/queries/group_variables.query.graphql';
import {
  ADD_MUTATION_ACTION,
  DELETE_MUTATION_ACTION,
  GRAPHQL_GROUP_TYPE,
  UPDATE_MUTATION_ACTION,
  genericMutationErrorText,
  variableFetchErrorText,
} from '../constants';
import addGroupVariable from '../graphql/mutations/group_add_variable.mutation.graphql';
import deleteGroupVariable from '../graphql/mutations/group_delete_variable.mutation.graphql';
import updateGroupVariable from '../graphql/mutations/group_update_variable.mutation.graphql';
import CiVariableSettings from './ci_variable_settings.vue';

export default {
  components: {
    CiVariableSettings,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['endpoint', 'groupPath', 'groupId'],
  data() {
    return {
      groupVariables: [],
    };
  },
  apollo: {
    groupVariables: {
      query: getGroupVariables,
      variables() {
        return {
          fullPath: this.groupPath,
        };
      },
      update(data) {
        return data?.group?.ciVariables?.nodes || [];
      },
      error() {
        createFlash({ message: variableFetchErrorText });
      },
    },
  },
  computed: {
    areScopedVariablesAvailable() {
      return this.glFeatures.groupScopedCiVariables;
    },
    isLoading() {
      return this.$apollo.queries.groupVariables.loading;
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
            fullPath: this.groupPath,
            groupId: convertToGraphQLId(GRAPHQL_GROUP_TYPE, this.groupId),
            variable,
          },
        });

        const { errors } = data[currentMutation.name];

        if (errors.length > 0) {
          createFlash({ message: errors[0] });
        }
      } catch {
        createFlash({ message: genericMutationErrorText });
      }
    },
  },
  mutationData: {
    [ADD_MUTATION_ACTION]: { action: addGroupVariable, name: 'addGroupVariable' },
    [UPDATE_MUTATION_ACTION]: { action: updateGroupVariable, name: 'updateGroupVariable' },
    [DELETE_MUTATION_ACTION]: { action: deleteGroupVariable, name: 'deleteGroupVariable' },
  },
};
</script>

<template>
  <ci-variable-settings
    :are-scoped-variables-available="areScopedVariablesAvailable"
    :is-loading="isLoading"
    :variables="groupVariables"
    @add-variable="addVariable"
    @delete-variable="deleteVariable"
    @update-variable="updateVariable"
  />
</template>
