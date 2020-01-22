<script>
import eventHub from '../event_hub';
import PipelinesActionsComponent from './pipelines_actions.vue';
import PipelinesArtifactsComponent from './pipelines_artifacts.vue';
import CiBadge from '../../vue_shared/components/ci_badge_link.vue';
import PipelineStage from './stage.vue';
import PipelineUrl from './pipeline_url.vue';
import PipelineTriggerer from './pipeline_triggerer.vue';
import PipelinesTimeago from './time_ago.vue';
import CommitComponent from '../../vue_shared/components/commit.vue';
import LoadingButton from '../../vue_shared/components/loading_button.vue';
import Icon from '../../vue_shared/components/icon.vue';
import { PIPELINES_TABLE } from '../constants';

/**
 * Pipeline table row.
 *
 * Given the received object renders a table row in the pipelines' table.
 */
export default {
  components: {
    PipelinesActionsComponent,
    PipelinesArtifactsComponent,
    CommitComponent,
    PipelineStage,
    PipelineUrl,
    PipelineTriggerer,
    CiBadge,
    PipelinesTimeago,
    LoadingButton,
    Icon,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
    updateGraphDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
    autoDevopsHelpPath: {
      type: String,
      required: true,
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
  pipelinesTable: PIPELINES_TABLE,
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
     * 2. if person who is an author of a commit is a GitLab user he/she can have a GitLab avatar
     * 3. If GitLab user does not have avatar he/she might have a Gravatar
     * 4. If committer is not a GitLab User he/she can have a Gravatar
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
        // he/she can have a GitLab avatar
        if (this.pipeline.commit.author.avatar_url) {
          commitAuthorInformation = this.pipeline.commit.author;

          // 3. If GitLab user does not have avatar he/she might have a Gravatar
        } else if (this.pipeline.commit.author_gravatar_url) {
          commitAuthorInformation = Object.assign({}, this.pipeline.commit.author, {
            avatar_url: this.pipeline.commit.author_gravatar_url,
          });
        }
        // 4. If committer is not a GitLab User he/she can have a Gravatar
      } else {
        commitAuthorInformation = {
          avatar_url: this.pipeline.commit.author_gravatar_url,
          path: `mailto:${this.pipeline.commit.author_email}`,
          username: this.pipeline.commit.author_name,
        };
      }

      return commitAuthorInformation;
    },

    /**
     * If provided, returns the commit tag.
     * Needed to render the commit component column.
     *
     * @returns {String|Undefined}
     */
    commitTag() {
      if (this.pipeline.ref && this.pipeline.ref.tag) {
        return this.pipeline.ref.tag;
      }
      return undefined;
    },

    /**
     * If provided, returns the commit ref.
     * Needed to render the commit component column.
     *
     * Matches `path` prop sent in the API to `ref_url` prop needed
     * in the commit component.
     *
     * @returns {Object|Undefined}
     */
    commitRef() {
      if (this.pipeline.ref) {
        return Object.keys(this.pipeline.ref).reduce((accumulator, prop) => {
          if (prop === 'path') {
            accumulator.ref_url = this.pipeline.ref[prop];
          } else {
            accumulator[prop] = this.pipeline.ref[prop];
          }
          return accumulator;
        }, {});
      }

      return undefined;
    },

    /**
     * If provided, returns the commit url.
     * Needed to render the commit component column.
     *
     * @returns {String|Undefined}
     */
    commitUrl() {
      if (this.pipeline.commit && this.pipeline.commit.commit_path) {
        return this.pipeline.commit.commit_path;
      }
      return undefined;
    },

    /**
     * If provided, returns the commit short sha.
     * Needed to render the commit component column.
     *
     * @returns {String|Undefined}
     */
    commitShortSha() {
      if (this.pipeline.commit && this.pipeline.commit.short_id) {
        return this.pipeline.commit.short_id;
      }
      return undefined;
    },

    /**
     * If provided, returns the commit title.
     * Needed to render the commit component column.
     *
     * @returns {String|Undefined}
     */
    commitTitle() {
      if (this.pipeline.commit && this.pipeline.commit.title) {
        return this.pipeline.commit.title;
      }
      return undefined;
    },

    /**
     * Timeago components expects a number
     *
     * @return {type}  description
     */
    pipelineDuration() {
      if (this.pipeline.details && this.pipeline.details.duration) {
        return this.pipeline.details.duration;
      }

      return 0;
    },

    /**
     * Timeago component expects a String.
     *
     * @return {String}
     */
    pipelineFinishedAt() {
      if (this.pipeline.details && this.pipeline.details.finished_at) {
        return this.pipeline.details.finished_at;
      }

      return '';
    },

    pipelineStatus() {
      if (this.pipeline.details && this.pipeline.details.status) {
        return this.pipeline.details.status;
      }
      return {};
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
          data-qa-selector="pipeline_commit_status"
        />
      </div>
    </div>

    <pipeline-url :pipeline="pipeline" :auto-devops-help-path="autoDevopsHelpPath" />
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
        <template v-if="pipeline.details.stages.length > 0">
          <div
            v-for="(stage, index) in pipeline.details.stages"
            :key="index"
            class="stage-container dropdown js-mini-pipeline-graph"
          >
            <pipeline-stage
              :type="$options.pipelinesTable"
              :stage="stage"
              :update-dropdown="updateGraphDropdown"
            />
          </div>
        </template>
      </div>
    </div>

    <pipelines-timeago :duration="pipelineDuration" :finished-time="pipelineFinishedAt" />

    <div
      v-if="displayPipelineActions"
      class="table-section section-20 table-button-footer pipeline-actions"
    >
      <div class="btn-group table-action-buttons">
        <pipelines-actions-component v-if="actions.length > 0" :actions="actions" />

        <pipelines-artifacts-component
          v-if="pipeline.details.artifacts.length"
          :artifacts="pipeline.details.artifacts"
          class="d-md-block"
        />

        <loading-button
          v-if="pipeline.flags.retryable"
          :loading="isRetrying"
          :disabled="isRetrying"
          container-class="js-pipelines-retry-button btn btn-default btn-retry"
          @click="handleRetryClick"
        >
          <icon name="repeat" />
        </loading-button>

        <loading-button
          v-if="pipeline.flags.cancelable"
          :loading="isCancelling"
          :disabled="isCancelling"
          data-toggle="modal"
          data-target="#confirmation-modal"
          container-class="js-pipelines-cancel-button btn btn-remove"
          @click="handleCancelClick"
        >
          <icon name="close" />
        </loading-button>
      </div>
    </div>
  </div>
</template>
