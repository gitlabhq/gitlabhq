/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VuePipeLines = Vue.extend({
    components: {
      'vue-running-pipeline': gl.VueRunningPipeline,
      'vue-stages': gl.VueStages,
      'vue-pipeline-actions': gl.VuePipelineActions,
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
      const url = window.location.href;
      if (url.includes('?')) this.pageNum = url.split('?')[1];
      // now fetch page appropriate data
      this.store.fetchDataLoop.call(this, Vue, this.pageNum);
    },
    methods: {
      shortSha(pipeline) {
        return pipeline.sha.slice(0, 8);
      },
      changePage() {
        // clearInterval(this.intervalId);
        // this.store.fetchDataLoop.call(this, Vue, this.pageNum);
      },
    },
    template: `
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
            <div class="icon-container">
              <i class="fa fa-code-fork"></i>
              </div>
              <!--
                I need to know which branch things are comming from
              -->
              <a class="monospace branch-name" href="./commits/master">master</a>
              <div class="icon-container commit-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 40 40">
                <path fill="#8F8F8F" fill-rule="evenodd" d="M28.7769836,18 C27.8675252,13.9920226 24.2831748,11 20,11 C15.7168252,11 12.1324748,13.9920226 11.2230164,18 L4.0085302,18 C2.90195036,18 2,18.8954305 2,20 C2,21.1122704 2.8992496,22 4.0085302,22 L11.2230164,22 C12.1324748,26.0079774 15.7168252,29 20,29 C24.2831748,29 27.8675252,26.0079774 28.7769836,22 L35.9914698,22 C37.0980496,22 38,21.1045695 38,20 C38,18.8877296 37.1007504,18 35.9914698,18 L28.7769836,18 L28.7769836,18 Z M20,25 C22.7614237,25 25,22.7614237 25,20 C25,17.2385763 22.7614237,15 20,15 C17.2385763,15 15,17.2385763 15,20 C15,22.7614237 17.2385763,25 20,25 L20,25 Z"></path>
              </svg>
            </div>
            <a
              class="commit-id monospace"
              href="./commit/{{pipeline.sha}}">{{shortSha(pipeline)}}
            </a>
            <p class="commit-title">
              <a
                href="mailto:james@jameslopez.es"
              >
                <!--
                  need Author Name
                  need Plural Version of Author Name: Rails has this built in
                  need gravatar HASH for author
                  need authors email
                -->
                <img
                  class="avatar has-tooltip s20 hidden-xs"
                  alt="James Lopez's avatar"
                  title="James Lopez"
                  data-container="body"
                  src="http://www.gravatar.com/avatar/80d3b651b4be1f1db39435c2d11f1f23?s=40&amp;d=identicon"
                >
              </a>
              <a
                class="commit-row-message"
                href="./commit/{{pipeline.sha}}"
              >
                <!--
                  need commit message/title for SHA
                -->
                fix broken repo 500 errors in UI and added relevant specs
              </a>
            </p>
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
                ex: <vue-stages :stages='stages'>
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
    `,
  });
})(window.gl || (window.gl = {}));
