/* global Vue, Flash, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueStage = Vue.extend({
    data() {
      return {
        request: false,
        builds: '<ul></ul>',
      };
    },
    props: ['stage', 'svgs', 'match'],
    computed: {
      buildStatus() {
        return `Build: ${this.stage.status.label}`;
      },
      tooltip() {
        return `has-tooltip ci-status-icon-${this.stage.status.group}`;
      },
      svg() {
        return this.svgs[this.match(this.stage.status.icon)];
      },
      spanClass() {
        return `ci-status-icon ci-status-icon-${this.stage.status.group}`;
      },
      methods: {
        fetchBuilds() {
          this.$http.get(this.stage.status.endpoint)
            .then((response) => {
              Vue.set(this, 'builds', response.html);
              Vue.set(this, 'response', true);
            }, () => new Flash(
              'Something went wrong on our end.',
            ));
        },
      },
    },
    template: `
      <div class="stage-container mini-pipeline-graph">
        <div class="dropdown inline build-content">
          <button
            class="has-tooltip builds-dropdown js-builds-dropdown-button"
            data-placement="top"
            data-stage-endpoint='stage.status.endpoint'
            data-title='stage.status.type'
            data-toggle="dropdown"
            type="button"
          >
            <span :class='tooltip'>
              <span class="mini-pipeline-graph-icon-container">
                <span
                  :class='spanClass'
                  :v-html='svg'
                >
                </span>
                <i class="fa fa-caret-down dropdown-caret"></i>
              </span>
            </span>
          </button>
          <div class="js-builds-dropdown-container">
            <div class="dropdown-menu grouped-pipeline-dropdown">
              <div class="arrow-up"></div>
              <div
                class="js-builds-dropdown-list"
                v-if='request'
                v-html='builds'
              >
              </div>
              <div
                class="js-builds-dropdown-loading builds-dropdown-loading"
                v-if='!request'
              >
                <span class="fa fa-spinner fa-spin"></span>
              </div>
            </div>
          </div>
        </div>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
