/* global Vue, gl */
/* eslint-disable no-param-reassign, no-bitwise*/

((gl) => {
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
        pagenum: 1,
        count: { all: 0, running_or_pending: 0 },
        pageRequest: false,
      };
    },
    props: ['scope', 'store', 'svgs'],
    created() {
      const pagenum = gl.getParameterByName('p');
      const scope = gl.getParameterByName('scope');
      if (pagenum) this.pagenum = pagenum;
      if (scope) this.apiScope = scope;
      this.store.fetchDataLoop.call(this, Vue, this.pagenum, this.scope, this.apiScope);
    },
    methods: {
      change(pagenum, apiScope) {
        window.history.pushState({}, null, `?scope=${apiScope}&p=${pagenum}`);
        clearInterval(this.timeLoopInterval);
        this.pageRequest = true;
        this.store.fetchDataLoop.call(this, Vue, pagenum, this.scope, apiScope);
      },
      author(pipeline) {
        if (!pipeline.commit) return ({ avatar_url: '', web_url: '', username: '' });
        if (pipeline.commit.author) return pipeline.commit.author;
        return ({
          avatar_url: pipeline.commit.author_gravatar_url,
          web_url: `mailto:${pipeline.commit.author_email}`,
          username: pipeline.commit.author_name,
        });
      },
      ref(pipeline) {
        const { ref } = pipeline;
        return ({ name: ref.name, tag: ref['tag?'], ref_url: ref.url });
      },
      commitTitle(pipeline) {
        if (pipeline.commit) return pipeline.commit.title;
        return '';
      },
      commitSha(pipeline) {
        if (pipeline.commit) return pipeline.commit.short_id;
        return '';
      },
      commitUrl(pipeline) {
        if (pipeline.commit) return pipeline.commit.commit_url;
        return '';
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
                    :commit-icon-svg='svgs.commitIconSvg'
                    :author='author(pipeline)'
                    :tag="pipeline.ref['tag?']"
                    :title='commitTitle(pipeline)'
                    :commit-ref='ref(pipeline)'
                    :short-sha='commitSha(pipeline)'
                    :commit-url='commitUrl(pipeline)'
                  >
                  </commit>
                </td>
                <stages :pipeline='pipeline'></stages>
                <time-ago :pipeline='pipeline'></time-ago>
                <pipeline-actions :pipeline='pipeline'></pipeline-actions>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="pipelines realtime-loading" v-if='pageRequest'>
          <i class="fa fa-spinner fa-spin"></i>
        </div>
        <gl-pagination
          v-if='pageInfo.total > pageInfo.perPage'
          :pagenum='pagenum'
          :change='change'
          :count='count.all'
          :pageInfo='pageInfo'
        >
        </gl-pagination>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
