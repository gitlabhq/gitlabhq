/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VuePipeLines = Vue.extend({
    components: {
      'vue-running-pipeline': gl.VueRunningPipeline,
      'vue-stages': gl.VueStages,
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
              <!-- I need to know which branch things are comming from -->
              <a class="monospace branch-name" href="/gitlab-org/gitlab-ce/commits/master">master</a>
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
                fix broken repo 500 errors in UI and added relevant specs
              </a>
            </p>
          </td>
          <td class="stage-cell">
            <vue-stages></vue-stages>
          </td>
          <td></td>
          <td class="pipeline-actions hidden-xs">
            <div class="controls pull-right">
            <div class="btn-group inline">
            <div class="btn-group">
            <a class="dropdown-toggle btn btn-default" data-toggle="dropdown" type="button">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 11" class="icon-play">
              <path fill-rule="evenodd" d="m9.283 6.47l-7.564 4.254c-.949.534-1.719.266-1.719-.576v-9.292c0-.852.756-1.117 1.719-.576l7.564 4.254c.949.534.963 1.392 0 1.934"></path>
              </svg>
            <i class="fa fa-caret-down"></i>
            </a>
            <ul class="dropdown-menu dropdown-menu-align-right">
            <li>
            <a rel="nofollow" data-method="post" href="/gitlab-org/gitlab-ce/builds/449/play"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 11" class="icon-play">
              <path fill-rule="evenodd" d="m9.283 6.47l-7.564 4.254c-.949.534-1.719.266-1.719-.576v-9.292c0-.852.756-1.117 1.719-.576l7.564 4.254c.949.534.963 1.392 0 1.934"></path>
              </svg>
            <span>Production</span>
            </a></li>
            </ul>
            </div>
            <div class="btn-group">
            <a class="dropdown-toggle btn btn-default build-artifacts" data-toggle="dropdown" type="button">
            <i class="fa fa-download"></i>
            <i class="fa fa-caret-down"></i>
            </a>
            <ul class="dropdown-menu dropdown-menu-align-right">
            <li>
            <a rel="nofollow" href="/gitlab-org/gitlab-ce/builds/437/artifacts/download"><i class="fa fa-download"></i>
            <span>Download 'build:osx' artifacts</span>
            </a></li>
            <li>
            <a rel="nofollow" href="/gitlab-org/gitlab-ce/builds/436/artifacts/download"><i class="fa fa-download"></i>
            <span>Download 'build:linux' artifacts</span>
            </a></li>
            </ul>
            </div>
            </div>
            <div class="cancel-retry-btns inline">
              <a
                class="btn has-tooltip"
                title="Retry"
                rel="nofollow"
                data-method="post"
                href="pipelines/retry">
                <i class="fa fa-repeat"></i>
              </a>
            </div>
            </div>
          </td>
        </tr>
      </tbody>
    `,
  });
})(window.gl || (window.gl = {}));
