/* global Vue, Flash, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VuePipelineActions = Vue.extend({
    props: ['pipeline', 'svgs'],
    computed: {
      actions() {
        return this.pipeline.details.manual_actions.length > 0;
      },
      artifacts() {
        return this.pipeline.details.artifacts.length > 0;
      },
    },
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
              <a
                v-if='actions'
                class="dropdown-toggle btn btn-default js-pipeline-dropdown-manual-actions"
                data-toggle="dropdown"
                title="Manual build"
                alt="Manual Build"
              >
                <span v-html='svgs.iconPlay'></span>
                <i class="fa fa-caret-down"></i>
              </a>
              <ul class="dropdown-menu dropdown-menu-align-right">
                <li v-for='action in pipeline.details.manual_actions'>
                  <a
                    rel="nofollow"
                    data-method="post"
                    :href='action.url'
                    title="Manual build"
                  >
                    <span v-html='svgs.iconPlay'></span>
                    <span title="Manual build">{{action.name}}</span>
                  </a>
                </li>
              </ul>
            </div>
            <div class="btn-group">
              <a
                v-if='artifacts'
                class="dropdown-toggle btn btn-default build-artifacts js-pipeline-dropdown-download"
                data-toggle="dropdown"
                type="button"
              >
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
              v-if='pipeline.retry_url'
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
              title="Cancel"
              rel="nofollow"
              data-method="post"
              :href='pipeline.cancel_url'
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
