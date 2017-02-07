/* eslint-disable no-param-reassign */
/* global Vue */

require('../../vue_pipelines_index/status');
require('../../vue_pipelines_index/pipeline_url');
require('../../vue_pipelines_index/stage');
require('../../vue_pipelines_index/pipeline_actions');
require('../../vue_pipelines_index/time_ago');
require('./commit');
/**
 * Pipeline table row.
 *
 * Given the received object renders a table row in the pipelines' table.
 */
(() => {
  window.gl = window.gl || {};
  gl.pipelines = gl.pipelines || {};

  gl.pipelines.PipelinesTableRowComponent = Vue.component('pipelines-table-row-component', {

    props: {
      pipeline: {
        type: Object,
        required: true,
        default: () => ({}),
      },

      /**
       * TODO: Remove this when we have webpack;
       */
      svgs: {
        type: Object,
        required: true,
        default: () => ({}),
      },
    },

    components: {
      'commit-component': gl.CommitComponent,
      'pipeline-actions': gl.VuePipelineActions,
      'dropdown-stage': gl.VueStage,
      'pipeline-url': gl.VuePipelineUrl,
      'status-scope': gl.VueStatusScope,
      'time-ago': gl.VueTimeAgo,
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
       * Matched `url` prop sent in the API to `path` prop needed
       * in the commit component.
       *
       * @returns {Object|Undefined}
       */
      commitRef() {
        if (this.pipeline.ref) {
          return Object.keys(this.pipeline.ref).reduce((accumulator, prop) => {
            if (prop === 'url') {
              accumulator.path = this.pipeline.ref[prop];
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

    methods: {
      /**
       * FIXME: This should not be in this component but in the components that
       * need this function.
       *
       * Used to render SVGs in the following components:
       * - status-scope
       * - dropdown-stage
       *
       * @param  {String} string
       * @return {String}
       */
      match(string) {
        return string.replace(/_([a-z])/g, (m, w) => w.toUpperCase());
      },
    },

    template: `
      <tr class="commit">
        <status-scope
          :pipeline="pipeline"
          :svgs="svgs"
          :match="match">
        </status-scope>

        <pipeline-url :pipeline="pipeline"></pipeline-url>

        <td>
          <commit-component
            :tag="commitTag"
            :commit-ref="commitRef"
            :commit-url="commitUrl"
            :short-sha="commitShortSha"
            :title="commitTitle"
            :author="commitAuthor"
            :commit-icon-svg="svgs.commitIconSvg">
          </commit-component>
        </td>

        <td class="stage-cell">
          <div class="stage-container dropdown js-mini-pipeline-graph"
            v-if="pipeline.details.stages.length > 0"
            v-for="stage in pipeline.details.stages">
            <dropdown-stage
              :stage="stage"
              :svgs="svgs"
              :match="match">
            </dropdown-stage>
          </div>
        </td>

        <time-ago :pipeline="pipeline" :svgs="svgs"></time-ago>

        <pipeline-actions :pipeline="pipeline" :svgs="svgs"></pipeline-actions>
      </tr>
    `,
  });
})();
