/* eslint-disable no-param-reassign */

import AsyncButtonComponent from '../../vue_pipelines_index/components/async_button.vue';
import PipelinesActionsComponent from '../../vue_pipelines_index/components/pipelines_actions';
import PipelinesArtifactsComponent from '../../vue_pipelines_index/components/pipelines_artifacts';
import PipelinesStatusComponent from '../../vue_pipelines_index/components/status';
import PipelinesStageComponent from '../../vue_pipelines_index/components/stage';
import PipelinesUrlComponent from '../../vue_pipelines_index/components/pipeline_url';
import PipelinesTimeagoComponent from '../../vue_pipelines_index/components/time_ago';
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
            v-if="pipeline.flags.retryable"
            :service="service"
            :endpoint="pipeline.retry_path"
            css-class="js-pipelines-retry-button btn-default btn-retry"
            title="Retry"
            icon="repeat" />

          <async-button-component
            v-if="pipeline.flags.cancelable"
            :service="service"
            :endpoint="pipeline.cancel_path"
            css-class="js-pipelines-cancel-button btn-remove"
            title="Cancel"
            icon="remove"
            confirm-action-message="Are you sure you want to cancel this pipeline?" />
        </div>
      </td>
    </tr>
  `,
};
