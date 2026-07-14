<script>
import { GlKeysetPagination, GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

import { PIPELINE_ID_KEY } from '~/ci/constants';
import PipelinesEmptyState from '~/ci/common/empty_state/pipelines_empty_state.vue';
import PipelinesErrorState from '~/ci/common/empty_state/pipelines_error_state.vue';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import retryPipelineMutation from '~/ci/pipeline_details/graphql/mutations/retry_pipeline.mutation.graphql';
import cancelPipelineMutation from '~/ci/pipeline_details/graphql/mutations/cancel_pipeline.mutation.graphql';
import { PIPELINES_PER_PAGE } from '~/ci/pipelines_page/constants';

import getCommitPipelines from '../graphql/queries/get_commit_pipelines.query.graphql';
import commitPipelineStatusesUpdatedSubscription from '../graphql/subscriptions/commit_pipeline_statuses_updated.subscription.graphql';

export default {
  name: 'CommitPipelinesList',
  components: {
    GlKeysetPagination,
    GlLoadingIcon,
    PipelinesTable,
    PipelinesEmptyState,
    PipelinesErrorState,
  },
  props: {
    projectFullPath: {
      type: String,
      required: true,
    },
    commitSha: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      pipelines: {
        count: 0,
        nodes: [],
        pageInfo: {},
        projectId: '',
      },
      pipelinesError: false,
      page: 1,
      pagination: {
        first: PIPELINES_PER_PAGE,
        last: null,
        before: null,
        after: null,
      },
    };
  },
  apollo: {
    pipelines: {
      query: getCommitPipelines,
      variables() {
        return {
          fullPath: this.projectFullPath,
          sha: this.commitSha,
          first: this.pagination.first,
          last: this.pagination.last,
          before: this.pagination.before,
          after: this.pagination.after,
        };
      },
      update(data) {
        this.pipelinesError = false;

        return {
          projectId: data?.project?.id || '',
          count: data?.project?.pipelines?.count || 0,
          nodes: data?.project?.pipelines?.nodes || [],
          pageInfo: data?.project?.pipelines?.pageInfo || {},
        };
      },
      error(err) {
        this.pipelinesError = true;
        this.captureError(err);
      },
      subscribeToMore: {
        document: commitPipelineStatusesUpdatedSubscription,
        variables() {
          return {
            projectId: this.pipelines?.projectId,
            sha: this.commitSha,
          };
        },
        skip() {
          return !this.pipelines?.projectId;
        },
        updateQuery(previousData, { subscriptionData }) {
          const updated = subscriptionData?.data?.ciPipelineStatusesUpdated;

          if (!updated) {
            return previousData;
          }

          const pipelines = previousData?.project?.pipelines;
          const nodes = pipelines?.nodes || [];
          const alreadyShown = nodes.some((node) => node.id === updated.id);

          if (alreadyShown || this.page > 1) {
            return previousData;
          }

          // Merge new pipeline into collection when on first page
          return {
            ...previousData,
            project: {
              ...previousData.project,
              pipelines: {
                ...pipelines,
                count: pipelines.count + 1,
                // Adds new pipeline at the top of the list
                nodes: [updated, ...nodes],
              },
            },
          };
        },
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.pipelines.loading;
    },
    hasPipelines() {
      return this.pipelines.nodes.length > 0;
    },
    showTable() {
      return !this.isLoading && !this.pipelinesError && this.hasPipelines;
    },
    showEmptyState() {
      return !this.isLoading && !this.pipelinesError && !this.hasPipelines;
    },
    showPagination() {
      return (
        !this.isLoading &&
        !this.pipelinesError &&
        (this.pipelines?.pageInfo?.hasNextPage || this.pipelines?.pageInfo?.hasPreviousPage)
      );
    },
  },
  watch: {
    'pipelines.count': {
      handler(count) {
        const updatePipelinesEvent = new CustomEvent('update-pipelines-count', {
          detail: { pipelineCount: count },
          bubbles: true,
        });

        if (this.$el) {
          this.$el.dispatchEvent(updatePipelinesEvent);
        }
      },
    },
  },
  methods: {
    async action({ pipeline, mutation, mutationType, defaultErrorMessage }) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation,
          variables: {
            id: pipeline.id,
          },
        });

        const [errorMessage] = data[mutationType]?.errors ?? [];

        if (errorMessage) {
          createAlert({ message: defaultErrorMessage });
          this.captureError(errorMessage);
        }
      } catch (err) {
        this.captureError(err);
      }
    },
    retryPipeline(pipeline) {
      this.action({
        pipeline,
        mutation: retryPipelineMutation,
        mutationType: 'pipelineRetry',
        defaultErrorMessage: s__('Pipelines|The pipeline could not be retried.'),
      });
    },
    cancelPipeline(pipeline) {
      this.action({
        pipeline,
        mutation: cancelPipelineMutation,
        mutationType: 'pipelineCancel',
        defaultErrorMessage: s__('Pipelines|The pipeline could not be canceled.'),
      });
    },
    nextPage() {
      this.page += 1;

      this.pagination = {
        first: PIPELINES_PER_PAGE,
        last: null,
        before: null,
        after: this.pipelines?.pageInfo?.endCursor,
      };
    },
    prevPage() {
      this.page -= 1;

      if (this.page === 1) {
        // Returning to first page should reload the newest pipelines from scratch (no cursor):
        // Pipelines created while we were paginated appear at the top.
        this.pagination = {
          first: PIPELINES_PER_PAGE,
          last: null,
          before: null,
          after: null,
        };
      } else {
        this.pagination = {
          first: null,
          last: PIPELINES_PER_PAGE,
          before: this.pipelines?.pageInfo?.startCursor,
          after: null,
        };
      }
    },
    captureError(err) {
      Sentry.captureException(err);
    },
  },
  pipelineIdKey: PIPELINE_ID_KEY,
};
</script>
<template>
  <div>
    <gl-loading-icon
      v-if="isLoading"
      :label="s__('Pipelines|Loading pipelines')"
      size="lg"
      class="gl-mt-6"
    />

    <pipelines-error-state v-else-if="pipelinesError" />

    <pipelines-empty-state
      v-else-if="showEmptyState"
      :title="s__('Pipelines|There are currently no pipelines.')"
    />

    <div v-else-if="showTable">
      <pipelines-table
        :pipelines="pipelines.nodes"
        :pipeline-id-type="$options.pipelineIdKey"
        class="@lg/panel:-gl-mt-px"
        @cancel-pipeline="cancelPipeline"
        @retry-pipeline="retryPipeline"
      />
      <div class="gl-mt-5 gl-flex gl-justify-center">
        <gl-keyset-pagination
          v-if="showPagination"
          v-bind="pipelines.pageInfo"
          @prev="prevPage"
          @next="nextPage"
        />
      </div>
    </div>
  </div>
</template>
