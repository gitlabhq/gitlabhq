/* global Vue, Flash, gl */
/* eslint-disable no-param-reassign */
const playIconSvg = require('../../../views/shared/icons/_icon_play.svg');

((gl) => {
  gl.VuePipelineActions = Vue.extend({
    props: ['pipeline'],
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

    data() {
      return { playIconSvg };
    },

    template: `
      <td class="pipeline-actions hidden-xs">
        <div class="controls pull-right">
          <div class="btn-group inline">
            <div class="btn-group">
              <button
                v-if='actions'
                class="dropdown-toggle btn btn-default has-tooltip js-pipeline-dropdown-manual-actions"
                data-toggle="dropdown"
                title="Manual job"
                data-placement="top"
                aria-label="Manual job"
              >
                <span v-html="playIconSvg" aria-hidden="true"></span>
                <i class="fa fa-caret-down" aria-hidden="true"></i>
              </button>
              <ul class="dropdown-menu dropdown-menu-align-right">
                <li v-for='action in pipeline.details.manual_actions'>
                  <a
                    rel="nofollow"
                    data-method="post"
                    :href='action.path'
                  >
                    <span v-html="playIconSvg" aria-hidden="true"></span>
                    <span>{{action.name}}</span>
                  </a>
                </li>
              </ul>
            </div>
            <div class="btn-group">
              <button
                v-if='artifacts'
                class="dropdown-toggle btn btn-default build-artifacts has-tooltip js-pipeline-dropdown-download"
                title="Artifacts"
                data-placement="top"
                data-toggle="dropdown"
                aria-label="Artifacts"
              >
                <i class="fa fa-download" aria-hidden="true"></i>
                <i class="fa fa-caret-down" aria-hidden="true"></i>
              </button>
              <ul class="dropdown-menu dropdown-menu-align-right">
                <li v-for='artifact in pipeline.details.artifacts'>
                  <a
                    rel="nofollow"
                    download
                    :href='artifact.path'
                  >
                    <i class="fa fa-download" aria-hidden="true"></i>
                    <span>{{download(artifact.name)}}</span>
                  </a>
                </li>
              </ul>
            </div>
          </div>
          <div class="cancel-retry-btns inline">
            <a
              v-if='pipeline.flags.retryable'
              class="btn has-tooltip"
              title="Retry"
              rel="nofollow"
              data-method="post"
              data-placement="top"
              data-toggle="dropdown"
              :href='pipeline.retry_path'
              aria-label="Retry">
              <i class="fa fa-repeat" aria-hidden="true"></i>
            </a>
            <a
              v-if='pipeline.flags.cancelable'
              class="btn btn-remove has-tooltip"
              title="Cancel"
              rel="nofollow"
              data-method="post"
              data-placement="top"
              data-toggle="dropdown"
              :href='pipeline.cancel_path'
              aria-label="Cancel">
              <i class="fa fa-remove" aria-hidden="true"></i>
            </a>
          </div>
        </div>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
