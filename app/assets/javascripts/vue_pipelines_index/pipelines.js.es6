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
      'vue-time-ago': gl.VueTimeAgo,
    },
    data() {
      return {
        pipelines: [],
        currentPage: '',
        intervalId: '',
        pagenum: 1,
        count: {
          all: 0,
          running_or_pending: 0,
        },
      };
    },
    props: [
      'scope',
      'store',
    ],
    created() {
      const url = window.location.toString();
      if (~url.indexOf('?')) this.pagenum = url.split('?')[1].split('=')[1];
      this.store.fetchDataLoop.call(this, Vue, this.pagenum, this.scope);
    },
    methods: {
      changepage(event, last) {
        const text = event.target.innerText;
        if (text === '...') return;
        if (/^-?[\d.]+(?:e-?\d+)?$/.test(text)) this.pagenum = +text;
        if (text === 'Last >>') this.pagenum = last;
        if (text === 'Next') this.pagenum = +this.pagenum + 1;
        if (text === 'Prev') this.pagenum = +this.pagenum - 1;
        if (text === '<< First') this.pagenum = 1;

        window.history.pushState({}, null, `?p=${this.pagenum}`);
        clearInterval(this.intervalId);
        this.store.fetchDataLoop.call(this, Vue, this.pagenum, this.scope);
      },
    },
    template: `
      <div>
        <div class="table-holder">
          <table class="table ci-table">
            <vue-pipeline-head></vue-pipeline-head>
            <tbody>
              <tr class="commit" v-for='pipeline in pipelines'>
                <vue-status-scope :pipeline='pipeline'></vue-status-scope>
                <vue-pipeline-url :pipeline='pipeline'></vue-pipeline-url>
                <vue-branch-commit :pipeline='pipeline'></vue-branch-commit>
                <vue-stages :pipeline='pipeline'></vue-stages>
                <vue-time-ago :pipeline='pipeline'></vue-time-ago>
                <vue-pipeline-actions></vue-pipeline-actions>
              </tr>
            </tbody>
          </table>
        </div>
        <vue-gl-pagination
          v-if='count.all > 0'
          :pagenum='pagenum'
          :changepage='changepage'
          :count='count.all'
        >
        </vue-gl-pagination>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
