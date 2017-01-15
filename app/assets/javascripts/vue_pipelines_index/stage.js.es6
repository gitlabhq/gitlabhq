/* global Vue, Flash, gl */
/* eslint-disable no-param-reassign, no-bitwise */

((gl) => {
  gl.VueStage = Vue.extend({
    data() {
      return {
        count: 0,
        builds: '',
        spinner: '<span class="fa fa-spinner fa-spin"></span>',
      };
    },
    props: ['stage', 'svgs', 'match'],
    methods: {
      fetchBuilds() {
        if (this.count > 0) return null;
        return this.$http.get(this.stage.dropdown_path)
          .then((response) => {
            this.count += 1;
            this.builds = JSON.parse(response.body).html;
          }, () => {
            const flash = new Flash('Something went wrong on our end.');
            return flash;
          });
      },
    },
    computed: {
      buildsOrSpinner() {
        return this.builds ? this.builds : this.spinner;
      },
      dropdownClass() {
        if (this.builds) return 'js-builds-dropdown-container';
        return 'js-builds-dropdown-loading builds-dropdown-loading';
      },
      buildStatus() {
        return `Build: ${this.stage.status.label}`;
      },
      tooltip() {
        return `has-tooltip ci-status-icon ci-status-icon-${this.stage.status.group}`;
      },
      svg() {
        const icon = this.stage.status.icon;
        const stageIcon = icon.replace(/icon/i, 'stage_icon');
        return this.svgs[this.match(stageIcon)];
      },
      triggerButtonClass() {
        return `mini-pipeline-graph-dropdown-toggle has-tooltip js-builds-dropdown-button ci-status-icon-${this.stage.status.group}`;
      },
    },
    template: `
      <div>
        <button
          @click='fetchBuilds'
          :class="triggerButtonClass"
          :title='stage.title'
          data-placement="top"
          data-toggle="dropdown"
          type="button">
          <span v-html="svg"></span>
          <i class="fa fa-caret-down "></i>
        </button>
        <ul class="dropdown-menu mini-pipeline-graph-dropdown-menu js-builds-dropdown-container">
          <div class="arrow-up"></div>
          <div :class="dropdownClass" class="js-builds-dropdown-list scrollable-menu" v-html="buildsOrSpinner"></div>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
