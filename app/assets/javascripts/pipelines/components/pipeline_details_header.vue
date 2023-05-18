<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import { LOAD_FAILURE, POST_FAILURE, DELETE_FAILURE, DEFAULT } from '../constants';
import getPipelineQuery from '../graphql/queries/get_pipeline_header_data.query.graphql';
import { getQueryHeaders } from './graph/utils';

const POLL_INTERVAL = 10000;

export default {
  name: 'PipelineDetailsHeader',
  finishedStatuses: ['FAILED', 'SUCCESS', 'CANCELED'],
  components: {
    CiBadgeLink,
    GlLoadingIcon,
  },
  errorTexts: {
    [LOAD_FAILURE]: __('We are currently unable to fetch data for the pipeline header.'),
    [POST_FAILURE]: __('An error occurred while making the request.'),
    [DELETE_FAILURE]: __('An error occurred while deleting the pipeline.'),
    [DEFAULT]: __('An unknown error occurred.'),
  },
  inject: {
    graphqlResourceEtag: {
      default: '',
    },
    paths: {
      default: {},
    },
    pipelineIid: {
      default: '',
    },
  },
  props: {
    name: {
      type: String,
      required: false,
      default: '',
    },
    totalJobs: {
      type: String,
      required: false,
      default: '',
    },
    computeCredits: {
      type: String,
      required: false,
      default: '',
    },
    yamlErrors: {
      type: String,
      required: false,
      default: '',
    },
    failureReason: {
      type: String,
      required: false,
      default: '',
    },
    badges: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  apollo: {
    pipeline: {
      context() {
        return getQueryHeaders(this.graphqlResourceEtag);
      },
      query: getPipelineQuery,
      variables() {
        return {
          fullPath: this.paths.fullProject,
          iid: this.pipelineIid,
        };
      },
      update: (data) => data.project.pipeline,
      error() {
        this.reportFailure(LOAD_FAILURE);
      },
      pollInterval: POLL_INTERVAL,
      watchLoading(isLoading) {
        if (!isLoading) {
          // To ensure apollo has updated the cache,
          // we only remove the loading state in sync with GraphQL
          this.isCanceling = false;
          this.isRetrying = false;
        }
      },
    },
  },
  data() {
    return {
      pipeline: null,
      failureMessages: [],
      failureType: null,
      isCanceling: false,
      isRetrying: false,
      isDeleting: false,
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.pipeline.loading;
    },
    hasError() {
      return this.failureType;
    },
    hasPipelineData() {
      return Boolean(this.pipeline);
    },
    isLoadingInitialQuery() {
      return this.$apollo.queries.pipeline.loading && !this.hasPipelineData;
    },
    detailedStatus() {
      return this.pipeline?.detailedStatus || {};
    },
    status() {
      return this.pipeline?.status;
    },
    isFinished() {
      return this.$options.finishedStatuses.includes(this.status);
    },
    shouldRenderContent() {
      return !this.isLoadingInitialQuery && this.hasPipelineData;
    },
    failure() {
      switch (this.failureType) {
        case LOAD_FAILURE:
          return {
            text: this.$options.errorTexts[LOAD_FAILURE],
            variant: 'danger',
          };
        case POST_FAILURE:
          return {
            text: this.$options.errorTexts[POST_FAILURE],
            variant: 'danger',
          };
        case DELETE_FAILURE:
          return {
            text: this.$options.errorTexts[DELETE_FAILURE],
            variant: 'danger',
          };
        default:
          return {
            text: this.$options.errorTexts[DEFAULT],
            variant: 'danger',
          };
      }
    },
  },
  methods: {
    reportFailure(errorType, errorMessages = []) {
      this.failureType = errorType;
      this.failureMessages = errorMessages;
    },
  },
};
</script>

<template>
  <div class="gl-mt-3">
    <gl-loading-icon v-if="loading" class="gl-text-left" size="lg" />
    <template v-else>
      <div class="gl-mb-2">
        <ci-badge-link :status="detailedStatus" />
      </div>
    </template>
  </div>
</template>
