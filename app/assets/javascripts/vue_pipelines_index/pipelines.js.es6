/* global Vue, gl */
/* eslint-disable no-param-reassign, no-bitwise*/

((gl) => {
  const REALTIME = false;
  const SPREAD = '...';
  const PREV = 'Prev';
  const NEXT = 'Next';
  const FIRST = '<< First';
  const LAST = 'Last >>';

  gl.VuePipelines = Vue.extend({
    components: {
      runningPipeline: gl.VueRunningPipeline,
      pipelineActions: gl.VuePipelineActions,
      stages: gl.VueStages,
      commit: gl.CommitComponent,
      pipelineUrl: gl.VuePipelineUrl,
      pipelineHead: gl.VuePipelineHead,
      glPagination: gl.VueGlPagination,
      statusScope: gl.VueStatusScope,
      timeAgo: gl.VueTimeAgo,
    },
    data() {
      return {
        pipelines: [],
        allTimeIntervals: [],
        intervalId: '',
        updatedAt: '',
        pagenum: 1,
        count: {
          all: 0,
          running_or_pending: 0,
        },
        pageRequest: false,
      };
    },
    props: [
      'scope',
      'store',
    ],
    created() {
      const url = window.location.toString();
      if (~url.indexOf('?') && !~url.indexOf('scope=pipelines')) {
        this.pagenum = url.split('?')[1].split('=')[1];
      }
      this.store.fetchDataLoop.call(this, Vue, this.pagenum, this.scope);
    },
    methods: {
      changepage(e, last) {
        const text = e.target.innerText;
        if (text === SPREAD) return;
        if (/^-?[\d.]+(?:e-?\d+)?$/.test(text)) this.pagenum = +text;
        if (text === LAST) this.pagenum = last;
        if (text === NEXT) this.pagenum = +this.pagenum + 1;
        if (text === PREV) this.pagenum = +this.pagenum - 1;
        if (text === FIRST) this.pagenum = 1;

        window.history.pushState({}, null, `?p=${this.pagenum}`);
        if (REALTIME) clearInterval(this.intervalId);
        this.pageRequest = true;
        this.store.fetchDataLoop.call(this, Vue, this.pagenum, this.scope);
      },
      author(pipeline) {
        const { commit } = pipeline;
        const author = commit.author;
        if (author) return author;

        const nonUser = {
          avatar_url: commit.author_gravatar_url,
          web_url: `mailto:${commit.author_email}`,
          username: commit.author_name,
        };

        return nonUser;
      },
      ref(pipeline) {
        const { ref } = pipeline;
        const commitRef = {
          name: ref.name,
          tag: ref['tag?'],
          ref_url: ref.url,
        };
        return commitRef;
      },
      addTimeInterval(id, that) {
        this.allTimeIntervals.push({ id, component: that });
      },
    },
    template: `
      <div>
        <div class="pipelines realtime-loading" v-if='pipelines.length < 1'>
          <i class="fa fa-spinner fa-spin"></i>
        </div>
        <div class="table-holder" v-if='pipelines.length > 0'>
          <table class="table ci-table">
            <pipeline-head></pipeline-head>
            <tbody>
              <tr class="commit" v-for='pipeline in pipelines'>
                <status-scope :pipeline='pipeline'></status-scope>
                <pipeline-url :pipeline='pipeline'></pipeline-url>
                <td>
                  <commit
                    :ref='ref(pipeline)'
                    :author='author(pipeline)'
                    :tag="pipeline.ref['tag?']"
                    :title='pipeline.commit.title'
                    :short_sha='pipeline.commit.short_id'
                    :commit_url='pipeline.commit.commit_url'
                  >
                  </commit>
                </td>
                <stages :pipeline='pipeline'></stages>
                <time-ago
                  :pipeline='pipeline'
                  :addTimeInterval='addTimeInterval'
                >
                </time-ago>
                <pipeline-actions :pipeline='pipeline'></pipeline-actions>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="pipelines realtime-loading" v-if='pageRequest'>
          <i class="fa fa-spinner fa-spin"></i>
        </div>
        <gl-pagination
          v-if='count.all > 30'
          :pagenum='pagenum'
          :changepage='changepage'
          :count='count.all'
        >
        </gl-pagination>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
