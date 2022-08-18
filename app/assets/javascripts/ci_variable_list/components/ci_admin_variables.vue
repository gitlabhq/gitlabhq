<script>
import createFlash from '~/flash';
import getAdminVariables from '../graphql/queries/variables.query.graphql';
import {
  ADD_MUTATION_ACTION,
  DELETE_MUTATION_ACTION,
  UPDATE_MUTATION_ACTION,
  genericMutationErrorText,
  variableFetchErrorText,
} from '../constants';
import addAdminVariable from '../graphql/mutations/admin_add_variable.mutation.graphql';
import deleteAdminVariable from '../graphql/mutations/admin_delete_variable.mutation.graphql';
import updateAdminVariable from '../graphql/mutations/admin_update_variable.mutation.graphql';
import ciVariableSettings from './ci_variable_settings.vue';

export default {
  components: {
    ciVariableSettings,
  },
  inject: ['endpoint'],
  data() {
    return {
      adminVariables: [],
      isInitialLoading: true,
    };
  },
  apollo: {
    adminVariables: {
      query: getAdminVariables,
      update(data) {
        return data?.ciVariables?.nodes || [];
      },
      error() {
        createFlash({ message: variableFetchErrorText });
      },
      watchLoading(flag) {
        if (!flag) {
          this.isInitialLoading = false;
        }
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.adminVariables.loading && this.isInitialLoading;
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
            variable,
          },
        });

        const { errors } = data[currentMutation.name];

        if (errors.length > 0) {
          createFlash({ message: errors[0] });
        } else {
          // The writing to cache for admin variable is not working
          // because there is no ID in the cache at the top level.
          // We therefore need to manually refetch.
          this.$apollo.queries.adminVariables.refetch();
        }
      } catch {
        createFlash({ message: genericMutationErrorText });
      }
    },
  },
  mutationData: {
    [ADD_MUTATION_ACTION]: { action: addAdminVariable, name: 'addAdminVariable' },
    [UPDATE_MUTATION_ACTION]: { action: updateAdminVariable, name: 'updateAdminVariable' },
    [DELETE_MUTATION_ACTION]: { action: deleteAdminVariable, name: 'deleteAdminVariable' },
  },
};
</script>

<template>
  <ci-variable-settings
    :are-scoped-variables-available="false"
    :is-loading="isLoading"
    :variables="adminVariables"
    @add-variable="addVariable"
    @delete-variable="deleteVariable"
    @update-variable="updateVariable"
  />
</template>
