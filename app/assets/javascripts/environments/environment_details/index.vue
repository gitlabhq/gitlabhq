<script>
import { GlLoadingIcon } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { logError } from '~/lib/logger';
import { toggleQueryPollingByVisibility, etagQueryHeaders } from '~/graphql_shared/utils';
import ConfirmRollbackModal from '~/environments/components/confirm_rollback_modal.vue';
import environmentDetailsQuery from '../graphql/queries/environment_details.query.graphql';
import environmentToRollbackQuery from '../graphql/queries/environment_to_rollback.query.graphql';
import { convertToDeploymentTableRow } from '../helpers/deployment_data_transformation_helper';
import EmptyState from './empty_state.vue';
import DeploymentsTable from './deployments_table.vue';
import Pagination from './pagination.vue';
import {
  ENVIRONMENT_DETAILS_QUERY_POLLING_INTERVAL,
  ENVIRONMENT_DETAILS_PAGE_SIZE,
} from './constants';

export default {
  components: {
    ConfirmRollbackModal,
    Pagination,
    DeploymentsTable,
    EmptyState,
    GlLoadingIcon,
  },
  inject: { graphqlEtagKey: { default: '' } },
  props: {
    projectFullPath: {
      type: String,
      required: true,
    },
    environmentName: {
      type: String,
      required: true,
    },
    after: {
      type: String,
      required: false,
      default: null,
    },
    before: {
      type: String,
      required: false,
      default: null,
    },
  },
  apollo: {
    project: {
      query: environmentDetailsQuery,
      variables() {
        return {
          projectFullPath: this.projectFullPath,
          environmentName: this.environmentName,
          first: this.before ? null : ENVIRONMENT_DETAILS_PAGE_SIZE,
          last: this.before ? ENVIRONMENT_DETAILS_PAGE_SIZE : null,
          after: this.after,
          before: this.before,
        };
      },
      pollInterval() {
        return this.graphqlEtagKey ? ENVIRONMENT_DETAILS_QUERY_POLLING_INTERVAL : null;
      },
      context() {
        return etagQueryHeaders('environment_details', this.graphqlEtagKey);
      },
    },
    environmentToRollback: {
      query: environmentToRollbackQuery,
    },
  },
  data() {
    return {
      project: {},
      environmentToRollback: {},
      isInitialPageDataReceived: false,
      isPrefetchingPages: false,
    };
  },
  computed: {
    deployments() {
      return (
        this.project.environment?.deployments.nodes.map((deployment) =>
          convertToDeploymentTableRow(deployment, this.project.environment),
        ) || []
      );
    },
    isLoading() {
      return this.$apollo.queries.project.loading;
    },
    isDeploymentTableShown() {
      return this.isInitialPageDataReceived === true && this.deployments.length > 0;
    },
    pageInfo() {
      return this.project.environment?.deployments.pageInfo || {};
    },
    isPaginationDisabled() {
      return this.isLoading || this.isPrefetchingPages;
    },
  },
  watch: {
    async project(newProject) {
      this.isInitialPageDataReceived = true;
      this.isPrefetchingPages = true;

      try {
        // TLDR: when we load a page, if there's next and/or previous pages existing, we'll load their data as well to improve percepted performance.
        const {
          endCursor,
          hasPreviousPage,
          hasNextPage,
          startCursor,
        } = newProject.environment.deployments.pageInfo;

        // At the moment we have a limit of deployments being requested only from a signle environment entity per query,
        // and apparently two batched queries count as one on server-side
        // to load both next and previous page data, we have to query them sequentially
        if (hasNextPage) {
          await this.$apollo.query({
            query: environmentDetailsQuery,
            variables: {
              projectFullPath: this.projectFullPath,
              environmentName: this.environmentName,
              first: ENVIRONMENT_DETAILS_PAGE_SIZE,
              after: endCursor,
              before: null,
              last: null,
            },
          });
        }

        if (hasPreviousPage) {
          await this.$apollo.query({
            query: environmentDetailsQuery,
            variables: {
              projectFullPath: this.projectFullPath,
              environmentName: this.environmentName,
              first: null,
              after: null,
              before: startCursor,
              last: ENVIRONMENT_DETAILS_PAGE_SIZE,
            },
          });
        }
      } catch (error) {
        logError(error);
      }

      this.isPrefetchingPages = false;
    },
  },
  errorCaptured(error) {
    Sentry.withScope((scope) => {
      scope.setTag('vue_component', 'EnvironmentDetailsIndex');

      Sentry.captureException(error);
    });
  },
  mounted() {
    if (this.graphqlEtagKey) {
      toggleQueryPollingByVisibility(
        this.$apollo.queries.project,
        ENVIRONMENT_DETAILS_QUERY_POLLING_INTERVAL,
      );
    }
  },
  methods: {
    resetPage() {
      this.$router.push({ query: {} });
    },
  },
};
</script>
<template>
  <div class="gl-relative gl-min-h-6">
    <div
      v-if="isLoading"
      class="gl-absolute gl-top-0 gl-left-0 gl-w-full gl-h-full gl-z-index-200 gl-bg-gray-10 gl-opacity-3"
    ></div>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-absolute gl-top-half gl-left-50p" />
    <div v-if="isDeploymentTableShown">
      <deployments-table :deployments="deployments" />
      <pagination :page-info="pageInfo" :disabled="isPaginationDisabled" />
    </div>
    <empty-state v-if="!isDeploymentTableShown && !isLoading" />
    <confirm-rollback-modal :environment="environmentToRollback" graphql @rollback="resetPage" />
  </div>
</template>
