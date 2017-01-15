/* global Vue, Flash, gl */
/* eslint-disable no-param-reassign, no-bitwise */

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
      fetchBuilds(e) {
        /**
          This is a very interesting UI problem
          Essentially we have to clear builds on blur no matter what
          This was preventing turbolinks to make the request to the link clicked
          Vue will always look at the VDOM element which is the button

          It has a special attribute 'aria-expanded':
            - which will let us know if it is expanded
            - once the build link is clicked
            - when someone clicks outside of the dropdown

          In order for this to work:
            - we check that the event has the correct aria attribute
            - we make sure that if it does, we check where the event is on the DOM
            - we also check to see if the event is on the DOM or the native browser client
        */

        const areaExpanded = e.currentTarget.attributes['aria-expanded'];

        if (areaExpanded && (areaExpanded.textContent === 'true')) {
          const related = e.relatedTarget;
          if (!related && e.sourceCapabilities) {
            return this.clearBuilds();
          } else if (!related && e.sourceCapabilities === null) {
            return null;
          } else if (!related && e.sourceCapabilities === undefined) {
            this.request = false;
            return null;
          } else if (!related.parentElement) {
            return this.clearBuilds();
          } else if (~related.parentElement.parentElement.className.indexOf('js-builds-dropdown-container')) {
            return null;
          }
        }

        if (this.request) return this.clearBuilds();

        return this.$http.get(this.stage.dropdown_path)
          .then((response) => {
            this.request = true;
            this.builds = JSON.parse(response.body).html;
          }, () => {
            const flash = new Flash('Something went wrong on our end.');
            this.request = false;
            return flash;
          });
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
          @click='fetchBuilds($event)'
          @blur='fetchBuilds($event)'
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
