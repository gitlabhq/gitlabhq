<script>
import { GlLoadingIcon, GlSorting } from '@gitlab/ui';
import { logError } from '~/lib/logger';
import { toggleQueryPollingByVisibility, etagQueryHeaders } from '~/graphql_shared/utils';
import ConfirmRollbackModal from '~/environments/components/confirm_rollback_modal.vue';
import { FINISHED_STATUSES } from '~/deployments/utils';
import environmentDetailsQuery from '../../graphql/queries/environment_details.query.graphql';
import environmentToRollbackQuery from '../../graphql/queries/environment_to_rollback.query.graphql';
import { convertToDeploymentTableRow } from '../../helpers/deployment_data_transformation_helper';
import EmptyState from '../empty_state.vue';
import DeploymentsTable from '../deployments_table.vue';
import Pagination from '../pagination.vue';
import {
  ENVIRONMENT_DETAILS_QUERY_POLLING_INTERVAL,
  ENVIRONMENT_DETAILS_PAGE_SIZE,
  DEPLOYMENTS_SORT_OPTIONS,
  DIRECTION_DESCENDING,
  DIRECTION_ASCENDING,
} from '../constants';

export default {
  components: {
    ConfirmRollbackModal,
    Pagination,
    DeploymentsTable,
    EmptyState,
    GlLoadingIcon,
    GlSorting,
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
          orderBy: this.orderBy,
          statuses: this.statuses,
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
      activeSortOption: DEPLOYMENTS_SORT_OPTIONS[0],
      sortDirection: DIRECTION_DESCENDING,
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
    pollingInterval() {
      return this.graphqlEtagKey ? ENVIRONMENT_DETAILS_QUERY_POLLING_INTERVAL : null;
    },
    isDirectionAscending() {
      return this.sortDirection === DIRECTION_ASCENDING;
    },
    orderBy() {
      return { [this.activeSortOption.value]: this.sortDirection };
    },
    statuses() {
      return this.activeSortOption.value === 'finishedAt' ? FINISHED_STATUSES : [];
    },
  },
  watch: {
    async project(newProject) {
      this.isInitialPageDataReceived = true;
      this.isPrefetchingPages = true;

      try {
        // TL;DR: when we load a page, if there's next and/or previous pages existing, we'll load their data as well to improve perceived performance.
        const { endCursor, hasPreviousPage, hasNextPage, startCursor } =
          newProject.environment.deployments.pageInfo;

        // At the moment we have a limit of deployments being requested only from a single environment entity per query,
        // and apparently two batched queries count as one on server-side
        // to load both next and previous page data, we have to query them sequentially
        if (hasNextPage) {
          await this.$apollo.query({
            query: environmentDetailsQuery,
            variables: {
              projectFullPath: this.projectFullPath,
              environmentName: this.environmentName,
              orderBy: this.orderBy,
              statuses: this.statuses,
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
              orderBy: this.orderBy,
              statuses: this.statuses,
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
    updateParams() {
      if (this.after || this.before) {
        this.resetPage();
      }
    },
    onDirectionChange() {
      this.sortDirection = this.isDirectionAscending ? DIRECTION_DESCENDING : DIRECTION_ASCENDING;
      this.updateParams();
    },
    onSortItemClick(orderBy) {
      this.activeSortOption = DEPLOYMENTS_SORT_OPTIONS.find((option) => option.value === orderBy);
      this.updateParams();
    },
  },
  sortOptions: DEPLOYMENTS_SORT_OPTIONS,
};
</script>
<template>
  <div class="gl-relative gl-min-h-6">
    <div
      v-if="isLoading"
      class="gl-absolute gl-left-0 gl-top-0 gl-z-200 gl-h-full gl-w-full gl-bg-subtle gl-opacity-3"
    ></div>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-absolute gl-left-1/2 gl-top-1/2" />
    <div v-if="isDeploymentTableShown">
      <div class="gl-my-3 gl-flex gl-justify-end">
        <gl-sorting
          :is-ascending="isDirectionAscending"
          :sort-options="$options.sortOptions"
          :sort-by="activeSortOption.value"
          @sortDirectionChange="onDirectionChange"
          @sortByChange="onSortItemClick"
        />
      </div>

      <deployments-table :deployments="deployments" />
      <pagination :page-info="pageInfo" :disabled="isPaginationDisabled" />
    </div>
    <empty-state v-if="!isDeploymentTableShown && !isLoading" />
    <confirm-rollback-modal :environment="environmentToRollback" graphql @rollback="resetPage" />
  </div>
</template>
