<script>
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { reportToSentry } from '~/ci/utils';
import {
  ENVIRONMENT_FETCH_ERROR,
  ENVIRONMENT_QUERY_LIMIT,
  mapEnvironmentNames,
} from '~/ci/common/private/ci_environments_dropdown';
import {
  ADD_MUTATION_ACTION,
  DELETE_MUTATION_ACTION,
  genericMutationErrorText,
  mapMutationActionToToast,
  SORT_DIRECTIONS,
  UPDATE_MUTATION_ACTION,
  variableFetchErrorText,
} from '../constants';
import CiVariableSettings from './ci_variable_settings.vue';

export default {
  components: {
    CiVariableSettings,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['endpoint'],
  props: {
    areScopedVariablesAvailable: {
      required: true,
      type: Boolean,
    },
    componentName: {
      required: true,
      type: String,
    },
    entity: {
      required: false,
      type: String,
      default: '',
    },
    fullPath: {
      required: false,
      type: String,
      default: null,
    },
    hideEnvironmentScope: {
      type: Boolean,
      required: false,
      default: false,
    },
    id: {
      required: false,
      type: String,
      default: null,
    },
    mutationData: {
      required: true,
      type: Object,
      validator: (obj) => {
        const hasValidKeys = Object.keys(obj).includes(
          ADD_MUTATION_ACTION,
          UPDATE_MUTATION_ACTION,
          DELETE_MUTATION_ACTION,
        );

        const hasValidValues = Object.values(obj).reduce((acc, val) => {
          return acc && typeof val === 'object';
        }, true);

        return hasValidKeys && hasValidValues;
      },
    },
    refetchAfterMutation: {
      required: false,
      type: Boolean,
      default: false,
    },
    queryData: {
      required: true,
      type: Object,
      validator: (obj) => {
        const { ciVariables, environments } = obj;
        const hasCiVariablesKey = Boolean(ciVariables);
        let hasCorrectEnvData = true;

        const hasCorrectVariablesData =
          typeof ciVariables?.lookup === 'function' && typeof ciVariables.query === 'object';

        if (environments) {
          hasCorrectEnvData =
            typeof environments?.lookup === 'function' && typeof environments.query === 'object';
        }

        return hasCiVariablesKey && hasCorrectVariablesData && hasCorrectEnvData;
      },
    },
  },
  data() {
    return {
      ciVariables: [],
      environments: [],
      hasNextPage: false,
      isInitialLoading: true,
      isLoadingMoreItems: false,
      loadingCounter: 0,
      mutationResponse: null,
      maxVariableLimit: 0,
      pageInfo: {},
      sortDirection: SORT_DIRECTIONS.ASC,
    };
  },
  apollo: {
    ciVariables: {
      query() {
        return this.queryData.ciVariables.query;
      },
      variables() {
        return {
          fullPath: this.fullPath || undefined,
          first: this.pageSize,
          sort: this.sortDirection,
        };
      },
      update(data) {
        return this.queryData.ciVariables.lookup(data)?.nodes || [];
      },
      result({ data }) {
        this.maxVariableLimit = this.queryData.ciVariables.lookup(data)?.limit || 0;

        this.pageInfo = this.queryData.ciVariables.lookup(data)?.pageInfo || this.pageInfo;

        if (!this.glFeatures?.ciVariablesPages) {
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
            createAlert({ message: this.$options.tooManyCallsError });
            reportToSentry(this.componentName, new Error(this.$options.tooManyCallsError));
          }
        }
      },
      error() {
        this.isLoadingMoreItems = false;
        this.hasNextPage = false;
        createAlert({ message: variableFetchErrorText });
      },
      watchLoading(flag) {
        if (!flag) {
          this.isInitialLoading = false;
        }
      },
    },
    environments: {
      query() {
        return this.queryData?.environments?.query || {};
      },
      skip() {
        return !this.hasEnvScopeQuery;
      },
      variables() {
        return {
          first: ENVIRONMENT_QUERY_LIMIT,
          fullPath: this.fullPath,
          search: '',
        };
      },
      update(data) {
        return mapEnvironmentNames(this.queryData.environments.lookup(data)?.nodes);
      },
      error() {
        createAlert({ message: ENVIRONMENT_FETCH_ERROR });
      },
    },
  },
  computed: {
    areEnvironmentsLoading() {
      return this.$apollo.queries.environments.loading;
    },
    areHiddenVariablesAvailable() {
      // group and project variables can be hidden, instance variables cannot
      return Boolean(this.entity);
    },
    hasEnvScopeQuery() {
      return Boolean(this.queryData?.environments?.query);
    },
    isLoading() {
      return (
        (this.$apollo.queries.ciVariables.loading && this.isInitialLoading) ||
        this.isLoadingMoreItems
      );
    },
    pageSize() {
      return this.glFeatures?.ciVariablesPages ? 20 : 100;
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

      this.$apollo.queries.ciVariables.fetchMore({
        variables: {
          after: this.pageInfo.endCursor,
        },
      });
    },
    handlePrevPage() {
      this.$apollo.queries.ciVariables.fetchMore({
        variables: {
          before: this.pageInfo.startCursor,
          first: null,
          last: this.pageSize,
        },
      });
    },
    handleNextPage() {
      this.$apollo.queries.ciVariables.fetchMore({
        variables: {
          after: this.pageInfo.endCursor,
          first: this.pageSize,
          last: null,
        },
      });
    },
    async handleSortChanged({ sortDesc }) {
      this.sortDirection = sortDesc ? SORT_DIRECTIONS.DESC : SORT_DIRECTIONS.ASC;

      // Wait for the new sort direction to be updated and then refetch
      await this.$nextTick();
      this.$apollo.queries.ciVariables.refetch();
    },
    updateVariable(variable) {
      this.variableMutation(UPDATE_MUTATION_ACTION, variable);
    },
    async searchEnvironmentScope(searchTerm) {
      this.$apollo.queries.environments.refetch({ search: searchTerm });
    },
    async variableMutation(mutationAction, variable) {
      try {
        const currentMutation = this.mutationData[mutationAction];

        const { data } = await this.$apollo.mutate({
          mutation: currentMutation,
          variables: {
            endpoint: this.endpoint,
            fullPath: this.fullPath || undefined,
            id: this.id || undefined,
            variable,
          },
        });

        if (data.ciVariableMutation?.errors?.length) {
          const { errors } = data.ciVariableMutation;
          const errorMessage = errors[0];

          if (mutationAction === DELETE_MUTATION_ACTION) {
            createAlert({ message: errorMessage });
          } else {
            this.mutationResponse = {
              hasError: true,
              message: errorMessage,
            };
          }
        } else {
          const successMessage = mapMutationActionToToast[mutationAction](variable.key);
          if (mutationAction === DELETE_MUTATION_ACTION) {
            this.$toast.show(successMessage);
          } else {
            this.mutationResponse = {
              hasError: false,
              message: successMessage,
            };
          }

          if (this.refetchAfterMutation) {
            // The writing to cache for admin variable is not working
            // because there is no ID in the cache at the top level.
            // We therefore need to manually refetch.
            this.$apollo.queries.ciVariables.refetch();
          }
        }
      } catch (e) {
        if (mutationAction === DELETE_MUTATION_ACTION) {
          createAlert({ message: genericMutationErrorText });
        } else {
          this.mutationResponse = {
            hasError: true,
            message: genericMutationErrorText,
          };
        }
      }
    },
  },
  i18n: {
    tooManyCallsError: __('Maximum number of variables loaded (2000)'),
  },
};
</script>

<template>
  <ci-variable-settings
    :are-environments-loading="areEnvironmentsLoading"
    :are-hidden-variables-available="areHiddenVariablesAvailable"
    :are-scoped-variables-available="areScopedVariablesAvailable"
    :entity="entity"
    :environments="environments"
    :hide-environment-scope="hideEnvironmentScope"
    :is-loading="isLoading"
    :max-variable-limit="maxVariableLimit"
    :mutation-response="mutationResponse"
    :page-info="pageInfo"
    :variables="ciVariables"
    @add-variable="addVariable"
    @delete-variable="deleteVariable"
    @handle-prev-page="handlePrevPage"
    @handle-next-page="handleNextPage"
    @sort-changed="handleSortChanged"
    @search-environment-scope="searchEnvironmentScope"
    @update-variable="updateVariable"
  />
</template>
