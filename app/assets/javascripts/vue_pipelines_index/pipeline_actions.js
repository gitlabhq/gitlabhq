/* global Vue, Flash, gl */
/* eslint-disable no-param-reassign,  no-alert */
const playIconSvg = require('icons/_icon_play.svg');

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

      /**
       * Shows a dialog when the user clicks in the cancel button.
       * We need to prevent the default behavior and stop propagation because the
       * link relies on UJS.
       *
       * @param  {Event} event
       */
      confirmAction(event) {
        if (!confirm('Are you sure you want to cancel this pipeline?')) {
          event.preventDefault();
          event.stopPropagation();
        }
      },
    },

    data() {
      return { playIconSvg };
    },

    template: `
      <td class="pipeline-actions">
        <div class="pull-right">
          <div class="btn-group">
            <div class="btn-group" v-if="actions">
              <button
                class="dropdown-toggle btn btn-default has-tooltip js-pipeline-dropdown-manual-actions"
                data-toggle="dropdown"
                title="Manual job"
                data-placement="top"
                data-container="body"
                aria-label="Manual job">
                <span v-html="playIconSvg" aria-hidden="true"></span>
                <i class="fa fa-caret-down" aria-hidden="true"></i>
              </button>
              <ul class="dropdown-menu dropdown-menu-align-right">
                <li v-for='action in pipeline.details.manual_actions'>
                  <a
                    rel="nofollow"
                    data-method="post"
                    :href="action.path" >
                    <span v-html="playIconSvg" aria-hidden="true"></span>
                    <span>{{action.name}}</span>
                  </a>
                </li>
              </ul>
            </div>

            <div class="btn-group" v-if="artifacts">
              <button
                class="dropdown-toggle btn btn-default build-artifacts has-tooltip js-pipeline-dropdown-download"
                title="Artifacts"
                data-placement="top"
                data-container="body"
                data-toggle="dropdown"
                aria-label="Artifacts">
                <i class="fa fa-download" aria-hidden="true"></i>
                <i class="fa fa-caret-down" aria-hidden="true"></i>
              </button>
              <ul class="dropdown-menu dropdown-menu-align-right">
                <li v-for='artifact in pipeline.details.artifacts'>
                  <a
                    rel="nofollow"
                    :href="artifact.path">
                    <i class="fa fa-download" aria-hidden="true"></i>
                    <span>{{download(artifact.name)}}</span>
                  </a>
                </li>
              </ul>
            </div>
            <div class="btn-group" v-if="pipeline.flags.retryable">
              <a
                class="btn btn-default btn-retry has-tooltip"
                title="Retry"
                rel="nofollow"
                data-method="post"
                data-placement="top"
                data-container="body"
                data-toggle="dropdown"
                :href='pipeline.retry_path'
                aria-label="Retry">
                <i class="fa fa-repeat" aria-hidden="true"></i>
              </a>
            </div>
            <div class="btn-group" v-if="pipeline.flags.cancelable">
              <a
                class="btn btn-remove has-tooltip"
                title="Cancel"
                rel="nofollow"
                data-method="post"
                data-placement="top"
                data-container="body"
                data-toggle="dropdown"
                :href='pipeline.cancel_path'
                aria-label="Cancel">
                <i class="fa fa-remove" aria-hidden="true"></i>
              </a>
            </div>
          </div>
        </div>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
