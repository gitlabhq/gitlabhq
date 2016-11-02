/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VuePipeLines = Vue.extend({
    components: {
      'vue-running-pipeline': gl.VueRunningPipeline,
      'vue-stages': gl.VueStages,
      'vue-pipeline-actions': gl.VuePipelineActions,
      'vue-branch-commit': gl.VueBranchCommit,
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
      // ** `.includes` does not work in PhantomJS

      // const url = window.location.toString();
      // if (url.includes('?')) this.pageNum = url.split('?')[1];
      // now fetch page appropriate data
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
    },
    template: `
      <div class="table-holder">
        <table class="table ci-table">
          <thead>
            <tr>
              <th>Status</th>
              <th>Pipeline</th>
              <th>Commit</th>
              <th>Stages</th>
              <th></th>
              <th class="hidden-xs"></th>
            </tr>
          </thead>
          <tbody v-for='pipeline in pipelines'>
            <tr class="commit">
              <td class="commit-link" v-if="pipeline.status === 'running'">
                <vue-running-pipeline :pipe='pipeline'></vue-running-pipeline>
              </td>
              <td>
                <a href="pipelines/{{pipeline.id}}">
                  <span class="pipeline-id">#{{pipeline.id}}</span>
                </a>
                <span>by</span>
                <span class="api monospace">{{pipeline.user}}</span>
              </td>
              <td class="branch-commit">
                <vue-branch-commit
                  :pipeline='pipeline'
                  :shortsha='shortsha'
                >
                </vue-branch-commit>
              </td>
              <td class="stage-cell">
                <!--
                  Need Stages Array:
                    ex: stage status per element as well as build name

                    Why I need it:
                      title="Prepare: failed" href="pipelines#prepare"
                      title="Notify Build: success" href="pipelines#notify_build"
                      title="Post Test: failed" href="pipelines#post-test"

                    How I would solve it once I have the data:
                      title="Prepare: {{stage.status}}"
                      href="pipelines#{{stage.title}}"

                  this way I can pass it as a prop to
                    ex:
                      <td class="stage-cell" v-for='stage in pipelines.stages'>
                        <vue-stage :stage='stage'>
                      </td>
                -->
                <vue-stages></vue-stages>
              </td>
              <td></td>
              <td class="pipeline-actions hidden-xs">
                <!-- will need to pass builds info and have v-if's for icons -->
                <vue-pipeline-actions></vue-pipeline-actions>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
