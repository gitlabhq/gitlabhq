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
      'vue-status-scope': gl.VueStatusScope,
    },
    data() {
      return {
        pipelines: [],
        currentPage: '',
        intervalId: '',
        pagenum: 1,
      };
    },
    props: [
      'scope',
      'store',
      'count',
    ],
    created() {
      const url = window.location.toString();
      if (~url.indexOf('?')) this.pagenum = url.split('?')[1].split('=')[1];
      this.store.fetchDataLoop.call(this, Vue, this.pagenum);
    },
    methods: {
      shortsha(pipeline) {
        return pipeline.sha.slice(0, 8);
      },
      changepage(event, last) {
        const text = event.target.innerText;
        if (typeof text === 'number') this.pagenum = +text;
        if (text === 'Last »') this.pagenum = last;
        if (text === 'Next') this.pagenum = +this.pagenum + 1;
        if (text === 'Prev') this.pagenum = +this.pagenum - 1;

        window.history.pushState({}, null, `?p=${this.pagenum}`);
        clearInterval(this.intervalId);
        this.store.fetchDataLoop.call(this, Vue, this.pagenum);
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
                <vue-status-scope
                  :scope='pipeline'
                  :scopeurl='pipelineurl'
                >
                </vue-status-scope>
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
          :pagenum='pagenum'
          :changepage='changepage'
          :count='count'
        >
        </vue-gl-pagination>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
