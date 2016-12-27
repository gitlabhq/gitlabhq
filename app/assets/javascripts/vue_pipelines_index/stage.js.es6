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
        if (this.request) return this.clearBuilds();

        return this.$http.get(this.stage.dropdown_path)
          .then((response) => {
            this.request = true;
            this.builds = JSON.parse(response.body).html;
          }, () => new Flash(
            'Something went wrong on our end.',
          ));
      },
      clearBuilds() {
        this.builds = '';
        this.request = false;
      },
    },
    computed: {
      buildsOrSpinner() {
        return this.request ? this.builds : this.spinner;
      },
      dropdownClass() {
        if (this.request) return 'js-builds-dropdown-container';
        return 'js-builds-dropdown-loading builds-dropdown-loading';
      },
      buildStatus() {
        return `Build: ${this.stage.status.label}`;
      },
      tooltip() {
        return `has-tooltip ci-status-icon-${this.stage.status.group}`;
      },
      svg() {
        const icon = this.stage.status.icon;
        icon.replace('icon', 'stageIcon');
        return this.svgs[this.match(icon)];
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
            @blur='fetchBuilds'
            class="has-tooltip builds-dropdown js-builds-dropdown-button"
            data-placement="top"
            :title='stage.title'
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
