<script>
import { produce } from 'immer';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { reportToSentry } from '~/ci/utils';
import CiVariableTable from '~/ci/ci_variable_list/components/ci_variable_table.vue';
import getInheritedCiVariables from '../graphql/queries/inherited_ci_variables.query.graphql';

export const i18n = {
  fetchError: s__('CiVariables|There was an error fetching the inherited CI variables.'),
  tooManyCallsError: s__(
    'CiVariables|Maximum number of Inherited Group CI variables loaded (2000)',
  ),
};

export const VARIABLES_PER_FETCH = 100;
export const FETCH_LIMIT = 20;

export default {
  name: 'InheritedCiVariablesApp',
  components: {
    CiVariableTable,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectPath'],
  apollo: {
    ciVariables: {
      query: getInheritedCiVariables,
      variables() {
        return {
          first: VARIABLES_PER_FETCH,
          fullPath: this.projectPath,
        };
      },
      update(data) {
        return data.project.inheritedCiVariables?.nodes || [];
      },
      result({ data }) {
        this.pageInfo = data?.project?.inheritedCiVariables?.pageInfo || this.pageInfo;
        this.hasNextPage = this.pageInfo?.hasNextPage || false;
        if (!this.hasNextPage) {
          return;
        }

        // The query fetches 100 items at a time.
        // Variables are batch loaded up to 20 consecutive API calls.
        if (this.loadingCounter < FETCH_LIMIT) {
          this.hasNextPage = false;
          this.fetchMoreVariables();
          this.loadingCounter += 1;
        } else {
          createAlert({ message: this.$options.i18n.tooManyCallsError });
          reportToSentry(this.$options.name, new Error(this.$options.i18n.tooManyCallsError));
        }
      },
      error() {
        this.showFetchError();
      },
    },
  },
  data() {
    return {
      ciVariables: [],
      hasNextPage: false,
      loadingCounter: 1,
      pageInfo: {},
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.ciVariables.loading;
    },
  },
  methods: {
    fetchMoreVariables() {
      this.$apollo.queries.ciVariables
        .fetchMore({
          variables: {
            after: this.pageInfo.endCursor,
          },
          updateQuery(previousResult, { fetchMoreResult }) {
            const previousVars = previousResult.project.inheritedCiVariables?.nodes;
            const newVars = fetchMoreResult.project.inheritedCiVariables?.nodes;

            return produce(fetchMoreResult, (draftData) => {
              draftData.project.inheritedCiVariables.nodes = previousVars.concat(newVars);
            });
          },
        })
        .catch(this.showFetchError);
    },
    showFetchError() {
      this.hasNextPage = false;
      createAlert({ message: this.$options.i18n.fetchError });
    },
  },
  i18n,
};
</script>

<template>
  <ci-variable-table
    entity="project"
    :is-loading="isLoading"
    :max-variable-limit="0"
    :page-info="pageInfo"
    :variables="ciVariables"
  />
</template>
