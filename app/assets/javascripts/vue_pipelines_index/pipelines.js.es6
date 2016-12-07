/* global Vue, gl */
/* eslint-disable no-param-reassign, no-bitwise*/

((gl) => {
  const SPREAD = '...';
  const PREV = 'Prev';
  const NEXT = 'Next';
  const FIRST = '<< First';
  const LAST = 'Last >>';

  const getParameterByName = (name) => {
    const url = window.location.href;
    name = name.replace(/[[\]]/g, '\\$&');
    const regex = new RegExp(`[?&]${name}(=([^&#]*)|&|#|$)`);
    const results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, ' '));
  };

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
        timeLoopInterval: '',
        intervalId: '',
        apiScope: 'all',
        pageInfo: {},
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
      const pagenum = getParameterByName('p');
      const scope = getParameterByName('scope');

      if (pagenum) this.pagenum = pagenum;
      if (scope) this.apiScope = scope;

      this.store.fetchDataLoop.call(
        this,
        Vue,
        this.pagenum,
        this.scope,
        this.apiScope,
      );
    },
    methods: {
      changepage(e) {
        const text = e.target.innerText;
        const { totalPages, nextPage, previousPage } = this.pageInfo;
        if (text === SPREAD) return;
        if (/^-?[\d.]+(?:e-?\d+)?$/.test(text)) this.pagenum = +text;
        if (text === LAST) this.pagenum = totalPages;
        if (text === NEXT) this.pagenum = nextPage;
        if (text === PREV) this.pagenum = previousPage;
        if (text === FIRST) this.pagenum = 1;

        window.history.pushState({}, null, `?p=${this.pagenum}`);
        clearInterval(this.timeLoopInterval);
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
      addTimeInterval(id, start) {
        this.allTimeIntervals.push({ id, start });
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
                    :author='author(pipeline)'
                    :tag="pipeline.ref['tag?']"
                    :title='pipeline.commit.title'
                    :commit_ref='ref(pipeline)'
                    :short_sha='pipeline.commit.short_id'
                    :commit_url='pipeline.commit.commit_url'
                  >
                  </commit>
                </td>
                <stages :pipeline='pipeline'></stages>
                <time-ago
                  :pipeline='pipeline'
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
          v-if='pageInfo.total > 30'
          :pagenum='pagenum'
          :changepage='changepage'
          :count='count.all'
          :pageInfo='pageInfo'
        >
        </gl-pagination>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
