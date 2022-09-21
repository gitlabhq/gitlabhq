<script>
import createFlash from '~/flash';
import { __ } from '~/locale';
import { reportMessageToSentry } from '../utils';
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
import CiVariableSettings from './ci_variable_settings.vue';

export default {
  components: {
    CiVariableSettings,
  },
  inject: ['endpoint'],
  data() {
    return {
      adminVariables: [],
      hasNextPage: false,
      isInitialLoading: true,
      isLoadingMoreItems: false,
      loadingCounter: 0,
      pageInfo: {},
    };
  },
  apollo: {
    adminVariables: {
      query: getAdminVariables,
      update(data) {
        return data?.ciVariables?.nodes || [];
      },
      result({ data }) {
        this.pageInfo = data?.ciVariables?.pageInfo || this.pageInfo;
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
      watchLoading(flag) {
        if (!flag) {
          this.isInitialLoading = false;
        }
      },
    },
  },
  computed: {
    isLoading() {
      return (
        (this.$apollo.queries.adminVariables.loading && this.isInitialLoading) ||
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

      this.$apollo.queries.adminVariables.fetchMore({
        variables: {
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
            variable,
          },
        });

        if (data[currentMutation.name]?.errors?.length) {
          const { errors } = data[currentMutation.name];
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
  componentName: 'InstanceVariables',
  i18n: {
    tooManyCallsError: __('Maximum number of variables loaded (2000)'),
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
