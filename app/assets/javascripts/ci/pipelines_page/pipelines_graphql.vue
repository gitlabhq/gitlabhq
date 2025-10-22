<script>
/*
  This component is the GraphQL version of `ci/pipelines_page/pipelines.vue`
  and is meant to eventually replace it.
*/
import NO_PIPELINES_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-pipeline-md.svg?url';
import ERROR_STATE_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-job-failed-md.svg?url';
import { GlEmptyState, GlKeysetPagination, GlLoadingIcon } from '@gitlab/ui';
import { createAlert, VARIANT_INFO } from '~/alert';
import { s__, __ } from '~/locale';
import { getParameterByName } from '~/lib/utils/url_utility';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import NoCiEmptyState from './components/empty_state/no_ci_empty_state.vue';
import NavigationControls from './components/nav_controls.vue';
import getPipelinesQuery from './graphql/queries/get_pipelines.query.graphql';
import clearRunnerCacheMutation from './graphql/mutations/clear_runner_cache.mutation.graphql';

import { PIPELINES_PER_PAGE } from './constants';

const DEFAULT_PAGINATION = {
  first: PIPELINES_PER_PAGE,
  last: null,
  before: null,
  after: null,
};

export default {
  errorStateSvgPath: ERROR_STATE_SVG,
  noPipelinesSvgPath: NO_PIPELINES_SVG,
  scopes: {
    all: 'all',
    finished: 'finished',
    branches: 'branches',
    tags: 'tags',
  },
  components: {
    GlEmptyState,
    GlKeysetPagination,
    GlLoadingIcon,
    NavigationControls,
    NavigationTabs,
    NoCiEmptyState,
    PipelinesTable,
    PipelineAccountVerificationAlert: () =>
      import('ee_component/vue_shared/components/pipeline_account_verification_alert.vue'),
  },
  inject: {
    fullPath: {
      default: '',
    },
    newPipelinePath: {
      default: '',
    },
    resetCachePath: {
      default: '',
    },
  },
  apollo: {
    pipelines: {
      query: getPipelinesQuery,
      variables() {
        // Map frontend scope to GraphQL scope
        const scopeMap = {
          all: null, // Don't filter - fetch all pipelines
          finished: this.$options.scopes.finished.toUpperCase(),
          branches: this.$options.scopes.branches.toUpperCase(),
          tags: this.$options.scopes.tags.toUpperCase(),
        };

        const variables = {
          fullPath: this.fullPath,
          first: this.pagination.first,
          last: this.pagination.last,
          after: this.pagination.after,
          before: this.pagination.before,
          scope: scopeMap[this.scope],
        };

        return variables;
      },
      update(data) {
        this.pipelinesError = false;

        return {
          projectId: data?.project?.id || '',
          list: data?.project?.pipelines?.nodes || [],
          pageInfo: data?.project?.pipelines?.pageInfo || {},
        };
      },
      error() {
        this.pipelinesError = true;
        createAlert({
          message: s__('Pipelines|An error occurred while loading pipelines'),
        });
      },
    },
  },
  data() {
    return {
      pipelines: {
        list: [],
        pageInfo: {},
      },
      pipelinesError: false,
      clearCacheLoading: false,
      scope: getParameterByName('scope') || 'all',
      pagination: {
        ...DEFAULT_PAGINATION,
      },
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.pipelines.loading;
    },
    hasPipelines() {
      return this.pipelines.list.length > 0;
    },
    isEmptyState() {
      return !this.isLoading && !this.pipelinesError && !this.hasPipelines;
    },
    showEmptyState() {
      return this.isEmptyState && this.scope === this.$options.scopes.all;
    },
    showEmptyTab() {
      return this.isEmptyState && this.scope !== this.$options.scopes.all;
    },
    showTable() {
      return !this.isLoading && !this.pipelinesError && this.hasPipelines;
    },
    emptyTabMessage() {
      if (this.scope === this.$options.scopes.finished) {
        return s__('Pipelines|There are currently no finished pipelines.');
      }

      return s__('Pipelines|There are currently no pipelines.');
    },
    shouldRenderTabs() {
      return !this.showEmptyState;
    },
    shouldRenderButtons() {
      return (this.newPipelinePath || this.resetCachePath) && this.shouldRenderTabs;
    },
    tabs() {
      const { scopes } = this.$options;

      return [
        {
          name: __('All'),
          scope: scopes.all,
          count: 0,
          isActive: this.scope === scopes.all,
        },
        {
          name: __('Finished'),
          scope: scopes.finished,
          isActive: this.scope === scopes.finished,
        },
        {
          name: __('Branches'),
          scope: scopes.branches,
          isActive: this.scope === scopes.branches,
        },
        {
          name: __('Tags'),
          scope: scopes.tags,
          isActive: this.scope === scopes.tags,
        },
      ];
    },
    showPagination() {
      return (
        !this.isLoading &&
        !this.pipelinesError &&
        (this.pipelines?.pageInfo?.hasNextPage || this.pipelines?.pageInfo?.hasPreviousPage)
      );
    },
  },
  methods: {
    onChangeTab(scope) {
      if (this.scope === scope) {
        return;
      }

      this.scope = scope;

      // Reset pagination when changing tabs
      // Apollo will automatically refetch with new variables
      this.pagination = { ...DEFAULT_PAGINATION };
    },
    nextPage() {
      this.pagination = {
        after: this.pipelines?.pageInfo?.endCursor,
        before: null,
        first: PIPELINES_PER_PAGE,
        last: null,
      };
    },
    prevPage() {
      this.pagination = {
        after: null,
        before: this.pipelines?.pageInfo?.startCursor,
        first: null,
        last: PIPELINES_PER_PAGE,
      };
    },
    async clearRunnerCache() {
      this.clearCacheLoading = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: clearRunnerCacheMutation,
          variables: {
            input: {
              projectId: this.pipelines.projectId,
            },
          },
        });

        if (data?.runnerCacheClear?.errors?.length > 0) {
          throw new Error();
        }

        createAlert({
          message: s__('Pipelines|Project cache successfully reset.'),
          variant: VARIANT_INFO,
        });
      } catch {
        createAlert({
          message: s__('Pipelines|Something went wrong while cleaning runners cache.'),
        });
      } finally {
        this.clearCacheLoading = false;
      }
    },
  },
};
</script>

<template>
  <div class="pipelines-container gl-mt-2">
    <pipeline-account-verification-alert class="gl-mt-5" />

    <div
      v-if="shouldRenderTabs || shouldRenderButtons"
      class="top-area scrolling-tabs-container inner-page-scroll-tabs gl-border-none"
    >
      <!-- Navigation -->
      <navigation-tabs
        v-if="shouldRenderTabs"
        :tabs="tabs"
        scope="pipelines"
        @onChangeTab="onChangeTab"
      />

      <navigation-controls
        v-if="shouldRenderButtons"
        :new-pipeline-path="newPipelinePath"
        :reset-cache-path="resetCachePath"
        :is-reset-cache-button-loading="clearCacheLoading"
        @resetRunnersCache="clearRunnerCache"
      />
    </div>

    <div class="content-list pipelines">
      <!-- Loading state -->
      <gl-loading-icon
        v-if="isLoading"
        :label="s__('Pipelines|Loading Pipelines')"
        class="gl-mt-5"
        size="lg"
      />

      <!-- Error state -->
      <gl-empty-state
        v-else-if="pipelinesError"
        :svg-path="$options.errorStateSvgPath"
        :title="s__('Pipelines|There was an error fetching the pipelines.')"
        :description="s__('Pipelines|Try again in a few moments or contact your support team.')"
      />

      <!-- Empty states -->
      <no-ci-empty-state
        v-else-if="showEmptyState"
        :empty-state-svg-path="$options.noPipelinesSvgPath"
      />

      <gl-empty-state
        v-else-if="showEmptyTab"
        :svg-path="$options.noPipelinesSvgPath"
        :title="emptyTabMessage"
      />

      <!-- Pipelines table -->
      <pipelines-table v-else-if="showTable" :pipelines="pipelines.list" />
    </div>

    <!-- Pagination -->
    <gl-keyset-pagination
      v-if="showPagination"
      v-bind="pipelines.pageInfo"
      class="gl-mt-5 gl-flex gl-justify-center"
      @prev="prevPage"
      @next="nextPage"
    />
  </div>
</template>
