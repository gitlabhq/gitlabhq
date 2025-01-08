<script>
import { GlFilteredSearch } from '@gitlab/ui';
import {
  OPERATOR_IS,
  OPERATORS_IS,
  TOKEN_TITLE_STATUS,
  TOKEN_TYPE_STATUS,
  TOKEN_TITLE_JOBS_RUNNER_TYPE,
  TOKEN_TYPE_JOBS_RUNNER_TYPE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import JobStatusToken from './tokens/job_status_token.vue';
import JobRunnerTypeToken from './tokens/job_runner_type_token.vue';

export default {
  components: {
    GlFilteredSearch,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    queryString: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    tokens() {
      const tokens = [
        {
          type: TOKEN_TYPE_STATUS,
          icon: 'status',
          title: TOKEN_TITLE_STATUS,
          unique: true,
          token: JobStatusToken,
          operators: OPERATORS_IS,
        },
      ];

      if (this.glFeatures.adminJobsFilterRunnerType) {
        tokens.push({
          type: TOKEN_TYPE_JOBS_RUNNER_TYPE,
          title: TOKEN_TITLE_JOBS_RUNNER_TYPE,
          unique: true,
          token: JobRunnerTypeToken,
          operators: OPERATORS_IS,
        });
      }

      return tokens;
    },
    filteredSearchValue() {
      return Object.entries(this.queryString || {}).reduce(
        (acc, [queryStringKey, queryStringValue]) => {
          switch (queryStringKey) {
            case 'statuses':
              return [
                ...acc,
                {
                  type: TOKEN_TYPE_STATUS,
                  value: { data: queryStringValue, operator: OPERATOR_IS },
                },
              ];
            case 'runnerTypes':
              if (!this.glFeatures.adminJobsFilterRunnerType) {
                return acc;
              }

              return [
                ...acc,
                {
                  type: TOKEN_TYPE_JOBS_RUNNER_TYPE,
                  value: { data: queryStringValue, operator: OPERATOR_IS },
                },
              ];
            case 'name':
              if (!this.glFeatures.feSearchBuildByName) {
                return acc;
              }

              return [
                ...acc,
                {
                  type: 'filtered-search-term',
                  value: { data: queryStringValue },
                },
              ];
            default:
              return acc;
          }
        },
        [],
      );
    },
  },
  methods: {
    onSubmit(filters) {
      this.$emit('filterJobsBySearch', filters);
    },
  },
};
</script>

<template>
  <gl-filtered-search
    v-if="glFeatures.feSearchBuildByName"
    :placeholder="s__('Jobs|Search or filter jobs...')"
    :available-tokens="tokens"
    :value="filteredSearchValue"
    :search-text-option-label="__('Search for this text')"
    terms-as-tokens
    @submit="onSubmit"
  />
  <gl-filtered-search
    v-else
    :placeholder="s__('Jobs|Filter jobs')"
    :available-tokens="tokens"
    :value="filteredSearchValue"
    @submit="onSubmit"
  />
</template>
