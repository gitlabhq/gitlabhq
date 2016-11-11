/* global Vue, gl */
/* eslint-disable no-param-reassign, no-bitwise*/

((gl) => {
  gl.VuePipeLines = Vue.extend({
    components: {
      'running-pipeline': gl.VueRunningPipeline,
      'stages': gl.VueStages,
      'pipeline-actions': gl.VuePipelineActions,
      'branch-commit': gl.VueBranchCommit,
      'pipeline-url': gl.VuePipelineUrl,
      'pipeline-head': gl.VuePipelineHead,
      'gl-pagination': gl.VueGlPagination,
      'status-scope': gl.VueStatusScope,
      'time-ago': gl.VueTimeAgo,
    },
    data() {
      return {
        pipelines: [],
        intervalId: '',
        updatedAt: '',
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
            <pipeline-head></pipeline-head>
            <tbody>
              <tr class="commit" v-for='pipeline in pipelines'>
                <status-scope :pipeline='pipeline'></status-scope>
                <pipeline-url :pipeline='pipeline'></pipeline-url>
                <branch-commit :pipeline='pipeline'></branch-commit>
                <stages :pipeline='pipeline'></stages>
                <time-ago :pipeline='pipeline'></time-ago>
                <pipeline-actions :pipeline='pipeline'></pipeline-actions>
              </tr>
            </tbody>
          </table>
        </div>
        <gl-pagination
          v-if='count.all > 0'
          :pagenum='pagenum'
          :changepage='changepage'
          :count='count.all'
        >
        </gl-pagination>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
