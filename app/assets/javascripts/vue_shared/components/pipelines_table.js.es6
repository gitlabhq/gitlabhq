/* eslint-disable no-param-reassign, no-new */
/* global Vue */
/* global PipelinesService */
/* global Flash */

//= require vue_pipelines_index/status.js.es6
//= require vue_pipelines_index/pipeline_url.js.es6
//= require vue_pipelines_index/stage.js.es6
//= require vue_pipelines_index/pipeline_actions.js.es6
//= require vue_pipelines_index/time_ago.js.es6
//= require vue_pipelines_index/pipelines.js.es6

(() => {
  window.gl = window.gl || {};
  gl.pipelines = gl.pipelines || {};

  gl.pipelines.PipelinesTableComponent = Vue.component('pipelines-table-component', {

    props: {

      /**
       * Stores the Pipelines to render.
       * It's passed as a prop to allow different stores to use this Component.
       * Different API calls can result in different responses, using a custom
       * store allows us to use the same pipeline component.
       */
      store: {
        type: Object,
        required: true,
        default: () => ({}),
      },

      /**
       * Will be used to fetch the needed data.
       * This component is used in different and therefore different API calls
       * to different endpoints will be made. To guarantee this is a reusable
       * component, the endpoint must be provided.
       */
      endpoint: {
        type: String,
        required: true,
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

    data() {
      return {
        state: this.store.state,
        isLoading: false,
      };
    },

    computed: {
      /**
       * If provided, returns the commit tag.
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
       *
       * @returns {String|Undefined}
       */
      commitTag() {
        if (this.model.last_deployment &&
          this.model.last_deployment.tag) {
          return this.model.last_deployment.tag;
        }
        return undefined;
      },

      /**
       * If provided, returns the commit ref.
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

      /**
       * Figure this out
       */
      match(string) {
        return string.replace(/_([a-z])/g, (m, w) => w.toUpperCase());
      },
    },

    /**
     * When the component is created the service to fetch the data will be
     * initialized with the correct endpoint.
     *
     * A request to fetch the pipelines will be made.
     * In case of a successfull response we will store the data in the provided
     * store, in case of a failed response we need to warn the user.
     *
     */
    created() {
      gl.pipelines.pipelinesService = new PipelinesService(this.endpoint);

      this.isLoading = true;

      return gl.pipelines.pipelinesService.all()
        .then(resp => resp.json())
        .then((json) => {
          this.store.storePipelines(json);
          this.isLoading = false;
        }).catch(() => {
          this.isLoading = false;
          new Flash('An error occurred while fetching the pipelines.', 'alert');
        });
    },
    // this need to be reusable between the 3 tables :/
    template: `
    <div>
      <div class="pipelines realtime-loading" v-if='isLoading'>
        <i class="fa fa-spinner fa-spin"></i>
      </div>


      <div class="blank-state blank-state-no-icon"
        v-if="!isLoading && state.pipelines.length === 0">
        <h2 class="blank-state-title js-blank-state-title">
          You don't have any pipelines.
        </h2>
        Put get started with pipelines button here!!!
      </div>

      <div class="table-holder" v-if='!isLoading state.pipelines.length > 0'>
        <table class="table ci-table">
          <thead>
            <tr>
              <th class="pipeline-status">Status</th>
              <th class="pipeline-info">Pipeline</th>
              <th class="pipeline-commit">Commit</th>
              <th class="pipeline-stages">Stages</th>
              <th class="pipeline-date"></th>
              <th class="pipeline-actions hidden-xs"></th>
            </tr>
          </thead>
          <tbody>
            <tr class="commit" v-for='pipeline in state.pipelines'>
              <status-scope
                :pipeline='pipeline'
                :match='match'
                :svgs='svgs'>
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
                  :commit-icon-svg="commitIconSvg">
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
          </tbody>
        </table>
      </div>
    </div>
    `,
  });
})();
