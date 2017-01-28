/* eslint-disable no-param-reassign */
/* global Vue */

//= require vue_pipelines_index/status
//= require vue_pipelines_index/pipeline_url
//= require vue_pipelines_index/stage
//= require vue_shared/components/commit
//= require vue_pipelines_index/pipeline_actions
//= require vue_pipelines_index/time_ago
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
       * Remove this. Find a better way to do this. don't want to provide this 3 times.
       */
      svgs: {
        type: Object,
        required: true,
        default: () => ({}),
      },
    },

    components: {
      'commit-component': gl.CommitComponent,
      runningPipeline: gl.VueRunningPipeline,
      pipelineActions: gl.VuePipelineActions,
      'vue-stage': gl.VueStage,
      pipelineUrl: gl.VuePipelineUrl,
      pipelineHead: gl.VuePipelineHead,
      statusScope: gl.VueStatusScope,
    },

    computed: {
      /**
       * If provided, returns the commit tag.
       * Needed to render the commit component column.
       *
       * @returns {Object|Undefined}
       */
      commitAuthor() {
        if (this.pipeline &&
          this.pipeline.commit &&
          this.pipeline.commit.author) {
          return this.pipeline.commit.author;
        }

        return undefined;
      },

      /**
       * If provided, returns the commit tag.
       * Needed to render the commit component column.
       *
       * @returns {String|Undefined}
       */
      commitTag() {
        // if (this.model.last_deployment &&
        //   this.model.last_deployment.tag) {
        //   return this.model.last_deployment.tag;
        // }
        return undefined;
      },

      /**
       * If provided, returns the commit ref.
       * Needed to render the commit component column.
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

      /**
       * Figure this out!
       * Needed to render the commit component column.
       */
      author(pipeline) {
        if (!pipeline.commit) return { avatar_url: '', web_url: '', username: '' };
        if (pipeline.commit.author) return pipeline.commit.author;
        return {
          avatar_url: pipeline.commit.author_gravatar_url,
          web_url: `mailto:${pipeline.commit.author_email}`,
          username: pipeline.commit.author_name,
        };
      },
    },

    methods: {
      match(string) {
        return string.replace(/_([a-z])/g, (m, w) => w.toUpperCase());
      },
    },

    template: `
      <tr class="commit">
        <status-scope
          :pipeline='pipeline'
          :svgs='svgs'
          :match="match">
        </status-scope>

        <pipeline-url :pipeline='pipeline'></pipeline-url>

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
          <div class="stage-container dropdown js-mini-pipeline-graph" v-for='stage in pipeline.details.stages'>
            <vue-stage :stage='stage' :svgs='svgs' :match='match'></vue-stage>
          </div>
        </td>

        <time-ago :pipeline='pipeline' :svgs='svgs'></time-ago>

        <pipeline-actions :pipeline='pipeline' :svgs='svgs'></pipeline-actions>
      </tr>
    `,
  });
})();
