/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueStage = Vue.extend({
    props: ['stage', 'svgs', 'match'],
    computed: {
      buildStatus() {
        return `Build: ${this.stage.status.label}`;
      },
      tooltip() {
        return `has-tooltip ci-status-icon-${this.stage.status.label}`;
      },
      svg() {
        return this.svgs[this.match(this.stage.status.icon)];
      },
    },
    template: `
      <a
        :class='tooltip'
        :title='buildStatus'
        :href='stage.path'
        v-html='svg'
      >
      </a>
    `,
  });
})(window.gl || (window.gl = {}));
