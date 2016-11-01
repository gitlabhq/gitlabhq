/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VuePipelineActions = Vue.extend({
    // props: ['builds'],
    template: `
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
        <!--
          Need builds ID for Play
        -->
        <a rel="nofollow" data-method="post" href="./builds/449/play"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 11" class="icon-play">
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
        <!--
          Need builds ID for OSX and LINUX
        -->
        <a rel="nofollow" href="./builds/437/artifacts/download"><i class="fa fa-download"></i>
        <span>Download 'build:osx' artifacts</span>
        </a></li>
        <li>
        <a rel="nofollow" href="./builds/436/artifacts/download"><i class="fa fa-download"></i>
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
    `,
  });
})(window.gl || (window.gl = {}));
