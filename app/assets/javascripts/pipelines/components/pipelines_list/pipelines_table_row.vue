<script>
import { GlButton, GlTooltipDirective, GlModalDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import CiBadge from '~/vue_shared/components/ci_badge_link.vue';
import CommitComponent from '~/vue_shared/components/commit.vue';
import eventHub from '../../event_hub';
import PipelineMiniGraph from './pipeline_mini_graph.vue';
import PipelineTriggerer from './pipeline_triggerer.vue';
import PipelineUrl from './pipeline_url.vue';
import PipelinesArtifactsComponent from './pipelines_artifacts.vue';
import PipelinesManualActionsComponent from './pipelines_manual_actions.vue';
import PipelinesTimeago from './time_ago.vue';

export default {
  i18n: {
    cancelTitle: __('Cancel'),
    redeployTitle: __('Retry'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModalDirective,
  },
  components: {
    PipelinesManualActionsComponent,
    PipelinesArtifactsComponent,
    CommitComponent,
    PipelineMiniGraph,
    PipelineUrl,
    PipelineTriggerer,
    CiBadge,
    PipelinesTimeago,
    GlButton,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
    pipelineScheduleUrl: {
      type: String,
      required: false,
      default: '',
    },
    updateGraphDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
    viewType: {
      type: String,
      required: true,
    },
    cancelingPipeline: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isRetrying: false,
    };
  },
  computed: {
    actions() {
      if (!this.pipeline || !this.pipeline.details) {
        return [];
      }
      const { details } = this.pipeline;
      return [...(details.manual_actions || []), ...(details.scheduled_actions || [])];
    },
    /**
     * If provided, returns the commit tag.
     * Needed to render the commit component column.
     *
     * This field needs a lot of verification, because of different possible cases:
     *
     * 1. person who is an author of a commit might be a GitLab user
     * 2. if person who is an author of a commit is a GitLab user, they can have a GitLab avatar
     * 3. If GitLab user does not have avatar they might have a Gravatar
     * 4. If committer is not a GitLab User they can have a Gravatar
     * 5. We do not have consistent API object in this case
     * 6. We should improve API and the code
     *
     * @returns {Object|Undefined}
     */
    commitAuthor() {
      let commitAuthorInformation;

      if (!this.pipeline || !this.pipeline.commit) {
        return null;
      }

      // 1. person who is an author of a commit might be a GitLab user
      if (this.pipeline.commit.author) {
        // 2. if person who is an author of a commit is a GitLab user
        // they can have a GitLab avatar
        if (this.pipeline.commit.author.avatar_url) {
          commitAuthorInformation = this.pipeline.commit.author;

          // 3. If GitLab user does not have avatar, they might have a Gravatar
        } else if (this.pipeline.commit.author_gravatar_url) {
          commitAuthorInformation = {
            ...this.pipeline.commit.author,
            avatar_url: this.pipeline.commit.author_gravatar_url,
          };
        }
        // 4. If committer is not a GitLab User, they can have a Gravatar
      } else {
        commitAuthorInformation = {
          avatar_url: this.pipeline.commit.author_gravatar_url,
          path: `mailto:${this.pipeline.commit.author_email}`,
          username: this.pipeline.commit.author_name,
        };
      }

      return commitAuthorInformation;
    },
    commitTag() {
      return this.pipeline?.ref?.tag;
    },
    commitRef() {
      return this.pipeline?.ref;
    },
    commitUrl() {
      return this.pipeline?.commit?.commit_path;
    },
    commitShortSha() {
      return this.pipeline?.commit?.short_id;
    },
    commitTitle() {
      return this.pipeline?.commit?.title;
    },
    pipelineStatus() {
      return this.pipeline?.details?.status ?? {};
    },
    hasStages() {
      return this.pipeline?.details?.stages?.length > 0;
    },
    displayPipelineActions() {
      return (
        this.pipeline.flags.retryable ||
        this.pipeline.flags.cancelable ||
        this.pipeline.details.manual_actions.length ||
        this.pipeline.details.artifacts.length
      );
    },
    isChildView() {
      return this.viewType === 'child';
    },
    isCancelling() {
      return this.cancelingPipeline === this.pipeline.id;
    },
  },
  watch: {
    pipeline() {
      this.isRetrying = false;
    },
  },
  methods: {
    handleCancelClick() {
      eventHub.$emit('openConfirmationModal', {
        pipeline: this.pipeline,
        endpoint: this.pipeline.cancel_path,
      });
    },
    handleRetryClick() {
      this.isRetrying = true;
      eventHub.$emit('retryPipeline', this.pipeline.retry_path);
    },
    handlePipelineActionRequestComplete() {
      // warn the pipelines table to update
      eventHub.$emit('refreshPipelinesTable');
    },
  },
};
</script>
<template>
  <div class="commit gl-responsive-table-row">
    <div class="table-section section-10 commit-link">
      <div class="table-mobile-header" role="rowheader">{{ s__('Pipeline|Status') }}</div>
      <div class="table-mobile-content">
        <ci-badge
          :status="pipelineStatus"
          :show-text="!isChildView"
          :icon-classes="'gl-vertical-align-middle!'"
          data-qa-selector="pipeline_commit_status"
        />
      </div>
    </div>

    <pipeline-url :pipeline="pipeline" :pipeline-schedule-url="pipelineScheduleUrl" />
    <pipeline-triggerer :pipeline="pipeline" />

    <div class="table-section section-wrap section-20">
      <div class="table-mobile-header" role="rowheader">{{ s__('Pipeline|Commit') }}</div>
      <div class="table-mobile-content">
        <commit-component
          :tag="commitTag"
          :commit-ref="commitRef"
          :commit-url="commitUrl"
          :merge-request-ref="pipeline.merge_request"
          :short-sha="commitShortSha"
          :title="commitTitle"
          :author="commitAuthor"
          :show-ref-info="!isChildView"
        />
      </div>
    </div>

    <div class="table-section section-wrap section-15 stage-cell">
      <div class="table-mobile-header" role="rowheader">{{ s__('Pipeline|Stages') }}</div>
      <div class="table-mobile-content">
        <pipeline-mini-graph
          v-if="hasStages"
          :stages="pipeline.details.stages"
          :update-dropdown="updateGraphDropdown"
          @pipelineActionRequestComplete="handlePipelineActionRequestComplete"
        />
      </div>
    </div>

    <pipelines-timeago class="gl-text-right" :pipeline="pipeline" />

    <div
      v-if="displayPipelineActions"
      class="table-section section-20 table-button-footer pipeline-actions"
    >
      <div class="btn-group table-action-buttons">
        <pipelines-manual-actions-component v-if="actions.length > 0" :actions="actions" />

        <pipelines-artifacts-component
          v-if="pipeline.details.artifacts.length"
          :artifacts="pipeline.details.artifacts"
        />

        <gl-button
          v-if="pipeline.flags.retryable"
          v-gl-tooltip.hover
          :aria-label="$options.i18n.redeployTitle"
          :title="$options.i18n.redeployTitle"
          :disabled="isRetrying"
          :loading="isRetrying"
          class="js-pipelines-retry-button"
          data-qa-selector="pipeline_retry_button"
          icon="repeat"
          variant="default"
          category="secondary"
          @click="handleRetryClick"
        />

        <gl-button
          v-if="pipeline.flags.cancelable"
          v-gl-tooltip.hover
          v-gl-modal-directive="'confirmation-modal'"
          :aria-label="$options.i18n.cancelTitle"
          :title="$options.i18n.cancelTitle"
          :loading="isCancelling"
          :disabled="isCancelling"
          icon="close"
          variant="danger"
          category="primary"
          class="js-pipelines-cancel-button"
          @click="handleCancelClick"
        />
      </div>
    </div>
  </div>
</template>
