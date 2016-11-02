/* global Vue, gl */
/* eslint-disable no-param-reassign, no-bitwise*/

((gl) => {
  gl.VuePipeLines = Vue.extend({
    components: {
      'vue-running-pipeline': gl.VueRunningPipeline,
      'vue-stages': gl.VueStages,
      'vue-pipeline-actions': gl.VuePipelineActions,
      'vue-branch-commit': gl.VueBranchCommit,
      'vue-pipeline-url': gl.VuePipelineUrl,
      'vue-pipeline-head': gl.VuePipelineHead,
    },
    data() {
      return {
        pipelines: [],
        currentPage: '',
        intervalId: '',
        pageNum: 'page=1',
      };
    },
    props: [
      'scope',
      'store',
    ],
    created() {
      const url = window.location.toString();
      if (~url.indexOf('?')) this.pageNum = url.split('?')[1];
      this.store.fetchDataLoop.call(this, Vue, this.pageNum);
    },
    methods: {
      shortsha(pipeline) {
        return pipeline.sha.slice(0, 8);
      },
      changePage() {
        // clearInterval(this.intervalId);
        // this.store.fetchDataLoop.call(this, Vue, this.pageNum);
      },
      pipelineurl(id) {
        return `pipelines/${id}`;
      },
    },
    template: `
      <div class="table-holder">
        <table class="table ci-table">
          <vue-pipeline-head></vue-pipeline-head>
          <tbody>
            <tr class="commit" v-for='pipeline in pipelines'>
              <td class="commit-link" v-if="pipeline.status">
                <vue-running-pipeline
                  :pipeline='pipeline'
                  :pipelineurl='pipelineurl'
                >
                </vue-running-pipeline>
              </td>
              <vue-pipeline-url
                :pipeline='pipeline'
                :pipelineurl='pipelineurl'
              >
              </vue-pipeline-url>
              <vue-branch-commit
                :pipeline='pipeline'
                :shortsha='shortsha'
              >
              </vue-branch-commit>
              <vue-stages></vue-stages>
              <td></td>
              <vue-pipeline-actions></vue-pipeline-actions>
            </tr>
          </tbody>
        </table>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
