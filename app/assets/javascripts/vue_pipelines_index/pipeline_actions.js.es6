/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VuePipelineActions = Vue.extend({
    props: [
      'pipeline',
    ],
    methods: {
      download(name) {
        return `Download ${name} artifacts`;
      },
    },
    template: `
      <td class="pipeline-actions hidden-xs">
        <div class="controls pull-right">
          <div class="btn-group inline">
            <div class="btn-group">
            <a class="dropdown-toggle btn btn-default" data-toggle="dropdown" type="button">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 11" class="icon-play">
                <path
                  fill-rule="evenodd"
                  d="m9.283 6.47l-7.564 4.254c-.949.534-1.719.266-1.719-.576v-9.292c0-.852.756-1.117 1.719-.576l7.564 4.254c.949.534.963 1.392 0 1.934"
                >
                </path>
              </svg>
              <i class="fa fa-caret-down"></i>
            </a>
            <ul class="dropdown-menu dropdown-menu-align-right">
              <li v-for='action in pipeline.details.manual_actions'>
                <a rel="nofollow" data-method="post" :href='action.url'>
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 11" class="icon-play">
                    <path
                      fill-rule="evenodd"
                      d="m9.283 6.47l-7.564 4.254c-.949.534-1.719.266-1.719-.576v-9.292c0-.852.756-1.117 1.719-.576l7.564 4.254c.949.534.963 1.392 0 1.934"
                    >
                    </path>
                  </svg>
                  <span>{{action.name}}</span>
                </a>
              </li>
            </ul>
            </div>
            <div class="btn-group">
              <a class="dropdown-toggle btn btn-default build-artifacts" data-toggle="dropdown" type="button">
                <i class="fa fa-download"></i>
                <i class="fa fa-caret-down"></i>
              </a>
              <ul class="dropdown-menu dropdown-menu-align-right">
                <li v-for='artifact in pipeline.details.artifacts'>
                  <a
                    rel="nofollow"
                    :href='artifact.url'
                  >
                    <i class="fa fa-download"></i>
                    <span>{{download(artifact.name)}}</span>
                  </a>
                </li>
              </ul>
            </div>
          </div>
          <div class="cancel-retry-btns inline">
            <a
              v-if='!pipeline.cancel_url'
              class="btn has-tooltip"
              title="Retry"
              rel="nofollow"
              data-method="post"
              :href='pipeline.retry_url'
            >
              <i class="fa fa-repeat"></i>
            </a>
            <a
              v-if='pipeline.cancel_url'
              class="btn btn-remove has-tooltip"
              title=""
              rel="nofollow"
              data-method="post"
              href="/gitlab-org/gitlab-ce/pipelines/4950216/cancel"
              data-original-title="Cancel"
            >
              <i class="fa fa-remove"></i>
            </a>
          </div>
        </div>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
