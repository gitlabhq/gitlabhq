<script>
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getGroupEnvironments } from '~/ci/common/private/ci_environments_dropdown';
import { ADD_MUTATION_ACTION, DELETE_MUTATION_ACTION, UPDATE_MUTATION_ACTION } from '../constants';
import getGroupVariables from '../graphql/queries/group_variables.query.graphql';
import addGroupVariable from '../graphql/mutations/group_add_variable.mutation.graphql';
import deleteGroupVariable from '../graphql/mutations/group_delete_variable.mutation.graphql';
import updateGroupVariable from '../graphql/mutations/group_update_variable.mutation.graphql';
import CiVariableShared from './ci_variable_shared.vue';

export default {
  components: {
    CiVariableShared,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['groupPath', 'groupId'],
  computed: {
    areScopedVariablesAvailable() {
      return this.glFeatures.groupScopedCiVariables;
    },
    graphqlId() {
      return convertToGraphQLId(TYPENAME_GROUP, this.groupId);
    },
  },
  mutationData: {
    [ADD_MUTATION_ACTION]: addGroupVariable,
    [UPDATE_MUTATION_ACTION]: updateGroupVariable,
    [DELETE_MUTATION_ACTION]: deleteGroupVariable,
  },
  queryData: {
    ciVariables: {
      lookup: (data) => data?.group?.ciVariables,
      query: getGroupVariables,
    },
    environments: {
      lookup: (data) => data?.group?.environmentScopes,
      query: getGroupEnvironments,
    },
  },
};
</script>

<template>
  <ci-variable-shared
    :id="graphqlId"
    :are-scoped-variables-available="areScopedVariablesAvailable"
    component-name="GroupVariables"
    entity="group"
    :full-path="groupPath"
    :mutation-data="$options.mutationData"
    :query-data="$options.queryData"
  />
</template>
