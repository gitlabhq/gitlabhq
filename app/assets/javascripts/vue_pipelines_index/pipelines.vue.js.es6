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
      'vue-gl-pagination': gl.VueGlPagination,
    },
    data() {
      return {
        pipelines: [],
        currentPage: '',
        intervalId: '',
        pageNum: 1,
      };
    },
    props: [
      'scope',
      'store',
    ],
    created() {
      const url = window.location.toString();
      if (~url.indexOf('?')) this.pageNum = url.split('?')[1].split('=')[1];
      this.store.fetchDataLoop.call(this, Vue, this.pageNum);
    },
    methods: {
      shortsha(pipeline) {
        return pipeline.sha.slice(0, 8);
      },
      changepage(event) {
        this.pageNum = +event.target.innerText;
        // use p instead of page to avoid rails tyring to make an actual request
        window.history.pushState({}, null, `?p=${this.pageNum}`);
        clearInterval(this.intervalId);
        this.store.fetchDataLoop.call(this, Vue, this.pageNum);
      },
      pipelineurl(id) {
        return `pipelines/${id}`;
      },
    },
    template: `
      <div>
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
        <vue-gl-pagination
          :changepage='changepage'
          :pages='pipelines.length'
        >
        </vue-gl-pagination>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
