<script>
import createFlash from '~/flash';
import { __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { reportMessageToSentry } from '../utils';
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
      hasNextPage: false,
      isLoadingMoreItems: false,
      loadingCounter: 0,
      pageInfo: {},
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
      result({ data }) {
        this.pageInfo = data?.group?.ciVariables?.pageInfo || this.pageInfo;
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
    areScopedVariablesAvailable() {
      return this.glFeatures.groupScopedCiVariables;
    },
    isLoading() {
      return this.$apollo.queries.groupVariables.loading || this.isLoadingMoreItems;
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

      this.$apollo.queries.groupVariables.fetchMore({
        variables: {
          fullPath: this.groupPath,
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
            fullPath: this.groupPath,
            groupId: convertToGraphQLId(GRAPHQL_GROUP_TYPE, this.groupId),
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
  componentName: 'GroupVariables',
  i18n: {
    tooManyCallsError: __('Maximum number of variables loaded (2000)'),
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
