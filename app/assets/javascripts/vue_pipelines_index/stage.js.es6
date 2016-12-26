/* global Vue, Flash, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueStage = Vue.extend({
    data() {
      return {
        request: false,
        builds: '',
        spinner: '<span class="fa fa-spinner fa-spin"></span>',
      };
    },
    props: ['stage', 'svgs', 'match'],
    methods: {
      fetchBuilds() {
        this.$http.get(this.endpoint)
          .then((response) => {
            this.request = true;
            setTimeout(() => {
              this.builds = JSON.parse(response.body).html;
            }, 100);
          }, () => new Flash(
            'Something went wrong on our end.',
          ));
      },
      clearState() {
        this.request = false;
        this.builds = '';
      },
    },
    computed: {
      buildsOrSpinner() {
        if (this.request) return this.builds;
        return this.spinner;
      },
      dropdownClass() {
        if (this.request) return 'js-builds-dropdown-container';
        return 'js-builds-dropdown-loading builds-dropdown-loading';
      },
      endpoint() {
        return '/gitlab-org/gitlab-shell/pipelines/121/stage?stage=deploy';
      },
      stageTitle() {
        return 'deploy: running';
      },
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
    },
    template: `
      <div class="stage-container mini-pipeline-graph">
        <div class="dropdown inline build-content">
          <button
            @click='fetchBuilds'
            @blur='clearState'
            class="has-tooltip builds-dropdown js-builds-dropdown-button"
            data-placement="top"
            :title='stageTitle'
            data-toggle="dropdown"
            type="button"
          >
            <span :class='tooltip'>
              <span class="mini-pipeline-graph-icon-container">
                <span
                  :class='spanClass'
                  v-html='svg'
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
                :class='dropdownClass'
                v-if='request'
                v-html='buildsOrSpinner'
              >
              </div>
            </div>
          </div>
        </div>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
