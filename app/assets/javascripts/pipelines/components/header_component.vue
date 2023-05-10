<script>
import {
  GlAlert,
  GlButton,
  GlLoadingIcon,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import { setUrlFragment, redirectTo } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import CiHeader from '~/vue_shared/components/header_ci_component.vue';
import {
  LOAD_FAILURE,
  POST_FAILURE,
  DELETE_FAILURE,
  DEFAULT,
  BUTTON_TOOLTIP_RETRY,
  BUTTON_TOOLTIP_CANCEL,
} from '../constants';
import cancelPipelineMutation from '../graphql/mutations/cancel_pipeline.mutation.graphql';
import deletePipelineMutation from '../graphql/mutations/delete_pipeline.mutation.graphql';
import retryPipelineMutation from '../graphql/mutations/retry_pipeline.mutation.graphql';
import getPipelineQuery from '../graphql/queries/get_pipeline_header_data.query.graphql';
import { getQueryHeaders } from './graph/utils';

const DELETE_MODAL_ID = 'pipeline-delete-modal';
const POLL_INTERVAL = 10000;

export default {
  name: 'PipelineHeaderSection',
  BUTTON_TOOLTIP_RETRY,
  BUTTON_TOOLTIP_CANCEL,
  pipelineCancel: 'pipelineCancel',
  pipelineRetry: 'pipelineRetry',
  finishedStatuses: ['FAILED', 'SUCCESS', 'CANCELED'],
  components: {
    CiHeader,
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlModal,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
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
    pipelineId: {
      default: '',
    },
    pipelineIid: {
      default: '',
    },
  },
  modal: {
    id: DELETE_MODAL_ID,
    actionPrimary: {
      text: __('Delete pipeline'),
      attributes: {
        variant: 'danger',
      },
    },
    actionCancel: {
      text: __('Cancel'),
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
    deleteModalConfirmationText() {
      return __(
        'Are you sure you want to delete this pipeline? Doing so will expire all pipeline caches and delete all related objects, such as builds, logs, artifacts, and triggers. This action cannot be undone.',
      );
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
    canRetryPipeline() {
      const { retryable, userPermissions } = this.pipeline;

      return retryable && userPermissions.updatePipeline;
    },
    canCancelPipeline() {
      const { cancelable, userPermissions } = this.pipeline;

      return cancelable && userPermissions.updatePipeline;
    },
  },
  methods: {
    reportFailure(errorType, errorMessages = []) {
      this.failureType = errorType;
      this.failureMessages = errorMessages;
    },
    async postPipelineAction(name, mutation) {
      try {
        const {
          data: {
            [name]: { errors },
          },
        } = await this.$apollo.mutate({
          mutation,
          variables: { id: this.pipeline.id },
        });

        if (errors.length > 0) {
          this.isRetrying = false;

          this.reportFailure(POST_FAILURE, errors);
        } else {
          await this.$apollo.queries.pipeline.refetch();
          if (!this.isFinished) {
            this.$apollo.queries.pipeline.startPolling(POLL_INTERVAL);
          }
        }
      } catch {
        this.isRetrying = false;

        this.reportFailure(POST_FAILURE);
      }
    },
    cancelPipeline() {
      this.isCanceling = true;
      this.postPipelineAction(this.$options.pipelineCancel, cancelPipelineMutation);
    },
    retryPipeline() {
      this.isRetrying = true;
      this.postPipelineAction(this.$options.pipelineRetry, retryPipelineMutation);
    },
    async deletePipeline() {
      this.isDeleting = true;
      this.$apollo.queries.pipeline.stopPolling();

      try {
        const {
          data: {
            pipelineDestroy: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: deletePipelineMutation,
          variables: {
            id: this.pipeline.id,
          },
        });

        if (errors.length > 0) {
          this.reportFailure(DELETE_FAILURE, errors);
          this.isDeleting = false;
        } else {
          redirectTo(setUrlFragment(this.paths.pipelinesPath, 'delete_success'));
        }
      } catch {
        this.$apollo.queries.pipeline.startPolling(POLL_INTERVAL);
        this.reportFailure(DELETE_FAILURE);
        this.isDeleting = false;
      }
    },
  },
  DELETE_MODAL_ID,
};
</script>
<template>
  <div class="js-pipeline-header-container">
    <gl-alert v-if="hasError" :title="failure.text" :variant="failure.variant" :dismissible="false">
      <div v-for="(failureMessage, index) in failureMessages" :key="`failure-message-${index}`">
        {{ failureMessage }}
      </div>
    </gl-alert>
    <ci-header
      v-if="shouldRenderContent"
      :status="pipeline.detailedStatus"
      :time="pipeline.createdAt"
      :user="pipeline.user"
      :item-id="pipelineId"
      item-name="Pipeline"
    >
      <gl-button
        v-if="canRetryPipeline"
        v-gl-tooltip
        :aria-label="$options.BUTTON_TOOLTIP_RETRY"
        :title="$options.BUTTON_TOOLTIP_RETRY"
        :loading="isRetrying"
        :disabled="isRetrying"
        variant="confirm"
        data-testid="retryPipeline"
        class="js-retry-button"
        @click="retryPipeline()"
      >
        {{ __('Retry') }}
      </gl-button>

      <gl-button
        v-if="canCancelPipeline"
        v-gl-tooltip
        :aria-label="$options.BUTTON_TOOLTIP_CANCEL"
        :title="$options.BUTTON_TOOLTIP_CANCEL"
        :loading="isCanceling"
        :disabled="isCanceling"
        class="gl-ml-3"
        variant="danger"
        data-testid="cancelPipeline"
        @click="cancelPipeline()"
      >
        {{ __('Cancel pipeline') }}
      </gl-button>

      <gl-button
        v-if="pipeline.userPermissions.destroyPipeline"
        v-gl-modal="$options.modal.id"
        :loading="isDeleting"
        :disabled="isDeleting"
        class="gl-ml-3"
        variant="danger"
        category="secondary"
        data-testid="deletePipeline"
      >
        {{ __('Delete') }}
      </gl-button>
    </ci-header>
    <gl-loading-icon v-if="isLoadingInitialQuery" size="lg" class="gl-mt-3 gl-mb-3" />

    <gl-modal
      :modal-id="$options.modal.id"
      :title="__('Delete pipeline')"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      @primary="deletePipeline()"
    >
      <p>
        {{ deleteModalConfirmationText }}
      </p>
    </gl-modal>
  </div>
</template>
