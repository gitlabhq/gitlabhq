/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VuePipeLines = Vue.extend({
    components: {
      'vue-running-pipeline': gl.VueRunningPipeline,
    },
    data() {
      return {
        pipelines: [],
        commits: [],
      };
    },
    props: [
      'scope',
      'store',
    ],
    created() {
      this.store.fetchCommits.call(this, Vue);
      this.store.fetchDataLoop.call(this, Vue);
    },
    methods: {
      shortSha(pipeline) {
        return pipeline.sha.slice(0, 8);
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
              <a class="monospace branch-name" href="/gitlab-org/gitlab-ce/commits/master">master</a>
              <div class="icon-container commit-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 40 40">
                <path fill="#8F8F8F" fill-rule="evenodd" d="M28.7769836,18 C27.8675252,13.9920226 24.2831748,11 20,11 C15.7168252,11 12.1324748,13.9920226 11.2230164,18 L4.0085302,18 C2.90195036,18 2,18.8954305 2,20 C2,21.1122704 2.8992496,22 4.0085302,22 L11.2230164,22 C12.1324748,26.0079774 15.7168252,29 20,29 C24.2831748,29 27.8675252,26.0079774 28.7769836,22 L35.9914698,22 C37.0980496,22 38,21.1045695 38,20 C38,18.8877296 37.1007504,18 35.9914698,18 L28.7769836,18 L28.7769836,18 Z M20,25 C22.7614237,25 25,22.7614237 25,20 C25,17.2385763 22.7614237,15 20,15 C17.2385763,15 15,17.2385763 15,20 C15,22.7614237 17.2385763,25 20,25 L20,25 Z"></path>
              </svg>
            </div>
            <a
              class="commit-id monospace"
              href="/gitlab-org/gitlab-ce/commit/{{pipeline.sha}}">{{shortSha(pipeline)}}
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
                href="/gitlab-org/gitlab-ce/commit/{{pipeline.sha}}"
              >
                fix broken repo 500 errors in UI and added relevant specs
              </a>
            </p>
          </td>
          <td class="stage-cell">
          <div class="stage-container">
          <a class="has-tooltip ci-status-icon-failed" title="Build: failed" href="pipelines#build"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
            <g fill="#D22852" fill-rule="evenodd">
              <path d="M12.5,7 C12.5,3.96243388 10.0375661,1.5 7,1.5 C3.96243388,1.5 1.5,3.96243388 1.5,7 C1.5,10.0375661 3.96243388,12.5 7,12.5 C10.0375661,12.5 12.5,10.0375661 12.5,7 Z M0,7 C0,3.13400675 3.13400675,0 7,0 C10.8659932,0 14,3.13400675 14,7 C14,10.8659932 10.8659932,14 7,14 C3.13400675,14 0,10.8659932 0,7 Z"></path>
              <path d="M7.72916667,6.27083333 L7.72916667,4.28939247 C7.72916667,4.12531853 7.59703895,4 7.43405116,4 L6.56594884,4 C6.40541585,4 6.27083333,4.12956542 6.27083333,4.28939247 L6.27083333,6.27083333 L4.28939247,6.27083333 C4.12531853,6.27083333 4,6.40296105 4,6.56594884 L4,7.43405116 C4,7.59458415 4.12956542,7.72916667 4.28939247,7.72916667 L6.27083333,7.72916667 L6.27083333,9.71060753 C6.27083333,9.87468147 6.40296105,10 6.56594884,10 L7.43405116,10 C7.59458415,10 7.72916667,9.87043458 7.72916667,9.71060753 L7.72916667,7.72916667 L9.71060753,7.72916667 C9.87468147,7.72916667 10,7.59703895 10,7.43405116 L10,6.56594884 C10,6.40541585 9.87043458,6.27083333 9.71060753,6.27083333 L7.72916667,6.27083333 Z" transform="rotate(-45 7 7)"></path>
            </g>
          </svg>

          </a></div>
          <div class="stage-container">
          <a class="has-tooltip ci-status-icon-failed" title="Prepare: failed" href="pipelines#prepare"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
            <g fill="#D22852" fill-rule="evenodd">
              <path d="M12.5,7 C12.5,3.96243388 10.0375661,1.5 7,1.5 C3.96243388,1.5 1.5,3.96243388 1.5,7 C1.5,10.0375661 3.96243388,12.5 7,12.5 C10.0375661,12.5 12.5,10.0375661 12.5,7 Z M0,7 C0,3.13400675 3.13400675,0 7,0 C10.8659932,0 14,3.13400675 14,7 C14,10.8659932 10.8659932,14 7,14 C3.13400675,14 0,10.8659932 0,7 Z"></path>
              <path d="M7.72916667,6.27083333 L7.72916667,4.28939247 C7.72916667,4.12531853 7.59703895,4 7.43405116,4 L6.56594884,4 C6.40541585,4 6.27083333,4.12956542 6.27083333,4.28939247 L6.27083333,6.27083333 L4.28939247,6.27083333 C4.12531853,6.27083333 4,6.40296105 4,6.56594884 L4,7.43405116 C4,7.59458415 4.12956542,7.72916667 4.28939247,7.72916667 L6.27083333,7.72916667 L6.27083333,9.71060753 C6.27083333,9.87468147 6.40296105,10 6.56594884,10 L7.43405116,10 C7.59458415,10 7.72916667,9.87043458 7.72916667,9.71060753 L7.72916667,7.72916667 L9.71060753,7.72916667 C9.87468147,7.72916667 10,7.59703895 10,7.43405116 L10,6.56594884 C10,6.40541585 9.87043458,6.27083333 9.71060753,6.27083333 L7.72916667,6.27083333 Z" transform="rotate(-45 7 7)"></path>
            </g>
          </svg>

          </a></div>
          <div class="stage-container">
          <a class="has-tooltip ci-status-icon-success" title="Notify Build: success" href="pipelines#notify_build"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
            <g fill="#31AF64" fill-rule="evenodd">
              <path d="M12.5,7 C12.5,3.96243388 10.0375661,1.5 7,1.5 C3.96243388,1.5 1.5,3.96243388 1.5,7 C1.5,10.0375661 3.96243388,12.5 7,12.5 C10.0375661,12.5 12.5,10.0375661 12.5,7 Z M0,7 C0,3.13400675 3.13400675,0 7,0 C10.8659932,0 14,3.13400675 14,7 C14,10.8659932 10.8659932,14 7,14 C3.13400675,14 0,10.8659932 0,7 Z"></path>
              <path d="M7.29166667,7.875 L5.54840803,7.875 C5.38293028,7.875 5.25,8.00712771 5.25,8.17011551 L5.25,9.03821782 C5.25,9.19875081 5.38360183,9.33333333 5.54840803,9.33333333 L8.24853534,9.33333333 C8.52035522,9.33333333 8.75,9.11228506 8.75,8.83960819 L8.75,8.46475969 L8.75,4.07392947 C8.75,3.92144267 8.61787229,3.79166667 8.45488449,3.79166667 L7.58678218,3.79166667 C7.42624919,3.79166667 7.29166667,3.91804003 7.29166667,4.07392947 L7.29166667,7.875 Z" transform="rotate(45 7 6.563)"></path>
            </g>
          </svg>

          </a></div>
          <div class="stage-container">
          <a class="has-tooltip ci-status-icon-failed" title="Post Test: failed" href="pipelines#post-test"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
            <g fill="#D22852" fill-rule="evenodd">
              <path d="M12.5,7 C12.5,3.96243388 10.0375661,1.5 7,1.5 C3.96243388,1.5 1.5,3.96243388 1.5,7 C1.5,10.0375661 3.96243388,12.5 7,12.5 C10.0375661,12.5 12.5,10.0375661 12.5,7 Z M0,7 C0,3.13400675 3.13400675,0 7,0 C10.8659932,0 14,3.13400675 14,7 C14,10.8659932 10.8659932,14 7,14 C3.13400675,14 0,10.8659932 0,7 Z"></path>
              <path d="M7.72916667,6.27083333 L7.72916667,4.28939247 C7.72916667,4.12531853 7.59703895,4 7.43405116,4 L6.56594884,4 C6.40541585,4 6.27083333,4.12956542 6.27083333,4.28939247 L6.27083333,6.27083333 L4.28939247,6.27083333 C4.12531853,6.27083333 4,6.40296105 4,6.56594884 L4,7.43405116 C4,7.59458415 4.12956542,7.72916667 4.28939247,7.72916667 L6.27083333,7.72916667 L6.27083333,9.71060753 C6.27083333,9.87468147 6.40296105,10 6.56594884,10 L7.43405116,10 C7.59458415,10 7.72916667,9.87043458 7.72916667,9.71060753 L7.72916667,7.72916667 L9.71060753,7.72916667 C9.87468147,7.72916667 10,7.59703895 10,7.43405116 L10,6.56594884 C10,6.40541585 9.87043458,6.27083333 9.71060753,6.27083333 L7.72916667,6.27083333 Z" transform="rotate(-45 7 7)"></path>
            </g>
          </svg>

          </a></div>
          <div class="stage-container">
          <a class="has-tooltip ci-status-icon-running" title="Test: running" href="pipelines#test"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
            <g fill="#2D9FD8" fill-rule="evenodd">
              <path d="M12.5,7 C12.5,3.96243388 10.0375661,1.5 7,1.5 C3.96243388,1.5 1.5,3.96243388 1.5,7 C1.5,10.0375661 3.96243388,12.5 7,12.5 C10.0375661,12.5 12.5,10.0375661 12.5,7 Z M0,7 C0,3.13400675 3.13400675,0 7,0 C10.8659932,0 14,3.13400675 14,7 C14,10.8659932 10.8659932,14 7,14 C3.13400675,14 0,10.8659932 0,7 Z"></path>
              <path d="M7,3 C9.209139,3 11,4.790861 11,7 C11,9.209139 9.209139,11 7,11 C5.65802855,11 4.47040669,10.3391508 3.74481446,9.32513253 L7,7 L7,3 L7,3 Z"></path>
            </g>
          </svg>

          </a></div>
          <div class="stage-container">
          <a class="has-tooltip ci-status-icon-failed" title="Notify Test: failed" href="pipelines#notify_test"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
            <g fill="#D22852" fill-rule="evenodd">
              <path d="M12.5,7 C12.5,3.96243388 10.0375661,1.5 7,1.5 C3.96243388,1.5 1.5,3.96243388 1.5,7 C1.5,10.0375661 3.96243388,12.5 7,12.5 C10.0375661,12.5 12.5,10.0375661 12.5,7 Z M0,7 C0,3.13400675 3.13400675,0 7,0 C10.8659932,0 14,3.13400675 14,7 C14,10.8659932 10.8659932,14 7,14 C3.13400675,14 0,10.8659932 0,7 Z"></path>
              <path d="M7.72916667,6.27083333 L7.72916667,4.28939247 C7.72916667,4.12531853 7.59703895,4 7.43405116,4 L6.56594884,4 C6.40541585,4 6.27083333,4.12956542 6.27083333,4.28939247 L6.27083333,6.27083333 L4.28939247,6.27083333 C4.12531853,6.27083333 4,6.40296105 4,6.56594884 L4,7.43405116 C4,7.59458415 4.12956542,7.72916667 4.28939247,7.72916667 L6.27083333,7.72916667 L6.27083333,9.71060753 C6.27083333,9.87468147 6.40296105,10 6.56594884,10 L7.43405116,10 C7.59458415,10 7.72916667,9.87043458 7.72916667,9.71060753 L7.72916667,7.72916667 L9.71060753,7.72916667 C9.87468147,7.72916667 10,7.59703895 10,7.43405116 L10,6.56594884 C10,6.40541585 9.87043458,6.27083333 9.71060753,6.27083333 L7.72916667,6.27083333 Z" transform="rotate(-45 7 7)"></path>
            </g>
          </svg>

          </a></div>
          <div class="stage-container">
          <a class="has-tooltip ci-status-icon-skipped" title="Pages: skipped" href="pipelines#pages"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
            <g fill="#5C5C5C" fill-rule="evenodd">
              <path d="M12.5,7 C12.5,3.96243388 10.0375661,1.5 7,1.5 C3.96243388,1.5 1.5,3.96243388 1.5,7 C1.5,10.0375661 3.96243388,12.5 7,12.5 C10.0375661,12.5 12.5,10.0375661 12.5,7 Z M0,7 C0,3.13400675 3.13400675,0 7,0 C10.8659932,0 14,3.13400675 14,7 C14,10.8659932 10.8659932,14 7,14 C3.13400675,14 0,10.8659932 0,7 Z"></path>
              <rect width="8" height="2" x="3" y="6" transform="rotate(45 7 7)" rx=".5"></rect>
            </g>
          </svg>

          </a></div>
          <div class="stage-container">
          <a class="has-tooltip ci-status-icon-canceled" title="Deploy: canceled" href="pipelines#deploy"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
            <g fill="#5C5C5C" fill-rule="evenodd">
              <path d="M12.5,7 C12.5,3.96243388 10.0375661,1.5 7,1.5 C3.96243388,1.5 1.5,3.96243388 1.5,7 C1.5,10.0375661 3.96243388,12.5 7,12.5 C10.0375661,12.5 12.5,10.0375661 12.5,7 Z M0,7 C0,3.13400675 3.13400675,0 7,0 C10.8659932,0 14,3.13400675 14,7 C14,10.8659932 10.8659932,14 7,14 C3.13400675,14 0,10.8659932 0,7 Z"></path>
              <rect width="8" height="2" x="3" y="6" transform="rotate(45 7 7)" rx=".5"></rect>
            </g>
          </svg>

          </a></div>
          </td>
          <td>
          </td>
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
