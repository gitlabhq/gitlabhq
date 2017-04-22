/* eslint-disable no-param-reassign, no-alert */
import Flash from '../../flash';
import eventHub from '../../pipelines/event_hub';
import AsyncButtonComponent from '../../pipelines/components/async_button.vue';
import PipelinesActionsComponent from '../../pipelines/components/pipelines_actions';
import PipelinesArtifactsComponent from '../../pipelines/components/pipelines_artifacts';
import PipelinesStatusComponent from '../../pipelines/components/status';
import PipelinesStageComponent from '../../pipelines/components/stage';
import PipelinesUrlComponent from '../../pipelines/components/pipeline_url';
import PipelinesTimeagoComponent from '../../pipelines/components/time_ago';
import CommitComponent from './commit';

/**
 * Pipeline table row.
 *
 * Given the received object renders a table row in the pipelines' table.
 */
export default {
  props: {
    pipeline: {
      type: Object,
      required: true,
    },

    service: {
      type: Object,
      required: true,
    },

    isRetryable: {
      type: Boolean,
      required: true,
    },

    isCancelable: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isRetrying: false,
      isCancelling: false,
    };
  },
  components: {
    'async-button-component': AsyncButtonComponent,
    'pipelines-actions-component': PipelinesActionsComponent,
    'pipelines-artifacts-component': PipelinesArtifactsComponent,
    'commit-component': CommitComponent,
    'dropdown-stage': PipelinesStageComponent,
    'pipeline-url': PipelinesUrlComponent,
    'status-scope': PipelinesStatusComponent,
    'time-ago': PipelinesTimeagoComponent,
  },

  computed: {
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

      // 1. person who is an author of a commit might be a GitLab user
      if (this.pipeline &&
        this.pipeline.commit &&
        this.pipeline.commit.author) {
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
      }

      // 4. If committer is not a GitLab User he/she can have a Gravatar
      if (this.pipeline &&
        this.pipeline.commit) {
        commitAuthorInformation = {
          avatar_url: this.pipeline.commit.author_gravatar_url,
          web_url: `mailto:${this.pipeline.commit.author_email}`,
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
      if (this.pipeline.ref &&
        this.pipeline.ref.tag) {
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
      if (this.pipeline.commit &&
        this.pipeline.commit.commit_path) {
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
      if (this.pipeline.commit &&
        this.pipeline.commit.short_id) {
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
      if (this.pipeline.commit &&
        this.pipeline.commit.title) {
        return this.pipeline.commit.title;
      }
      return undefined;
    },
  },
  watch: {
    // we watch pipeline update bc we don't know when refreshPipelines is finished
    isRetryable() {
      this.resetRequestingState();
    },
    isCancelable() {
      this.resetRequestingState();
    },
  },
  methods: {
    resetRequestingState() {
      this.isRetrying = false;
      this.isCancelling = false;
    },
    cancelPipeline() {
      const confirmMessage = 'Are you sure you want to cancel this pipeline?';

      if (confirmMessage && confirm(confirmMessage)) {
        this.isCancelling = true;
        this.makeRequest(this.pipeline.cancel_path);
      }
    },
    retryPipeline() {
      this.isRetrying = true;
      this.makeRequest(this.pipeline.retry_path);
    },
    makeRequest(endpoint) {
      return this.service.postAction(endpoint)
        .then(() => eventHub.$emit('refreshPipelines'))
        .catch(() => new Flash('An error occured while making the request.'));
    },
  },
  template: `
    <tr class="commit">
      <status-scope :pipeline="pipeline"/>

      <pipeline-url :pipeline="pipeline"></pipeline-url>

      <td>
        <commit-component
          :tag="commitTag"
          :commit-ref="commitRef"
          :commit-url="commitUrl"
          :short-sha="commitShortSha"
          :title="commitTitle"
          :author="commitAuthor"/>
      </td>

      <td class="stage-cell">
        <div class="stage-container dropdown js-mini-pipeline-graph"
          v-if="pipeline.details.stages.length > 0"
          v-for="stage in pipeline.details.stages">
          <dropdown-stage :stage="stage"/>
        </div>
      </td>

      <time-ago :pipeline="pipeline"/>

      <td class="pipeline-actions">
        <div class="pull-right btn-group">
          <pipelines-actions-component
            v-if="pipeline.details.manual_actions.length"
            :actions="pipeline.details.manual_actions"
            :service="service" />

          <pipelines-artifacts-component
            v-if="pipeline.details.artifacts.length"
            :artifacts="pipeline.details.artifacts" />

          <async-button-component
            v-if="isRetryable"
            class="js-pipelines-retry-button btn-default btn-retry"
            @click.native="retryPipeline"
            :is-loading="isRetrying"
            title="Retry"
            icon="repeat"/>

          <async-button-component
            v-if="isCancelable"
            class="js-pipelines-cancel-button btn-remove"
            @click.native="cancelPipeline"
            :is-loading="isCancelling"
            title="Cancel"
            icon="remove"/>
        </div>
      </td>
    </tr>
  `,
};
