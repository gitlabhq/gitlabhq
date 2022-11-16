<script>
import { ADD_MUTATION_ACTION, DELETE_MUTATION_ACTION, UPDATE_MUTATION_ACTION } from '../constants';
import getAdminVariables from '../graphql/queries/variables.query.graphql';
import addAdminVariable from '../graphql/mutations/admin_add_variable.mutation.graphql';
import deleteAdminVariable from '../graphql/mutations/admin_delete_variable.mutation.graphql';
import updateAdminVariable from '../graphql/mutations/admin_update_variable.mutation.graphql';
import CiVariableShared from './ci_variable_shared.vue';

export default {
  components: {
    CiVariableShared,
  },
  mutationData: {
    [ADD_MUTATION_ACTION]: addAdminVariable,
    [UPDATE_MUTATION_ACTION]: updateAdminVariable,
    [DELETE_MUTATION_ACTION]: deleteAdminVariable,
  },
  queryData: {
    ciVariables: {
      lookup: (data) => data?.ciVariables,
      query: getAdminVariables,
    },
  },
};
</script>

<template>
  <ci-variable-shared
    :are-scoped-variables-available="false"
    component-name="InstanceVariables"
    :hide-environment-scope="true"
    :mutation-data="$options.mutationData"
    :refetch-after-mutation="true"
    :query-data="$options.queryData"
  />
</template>
