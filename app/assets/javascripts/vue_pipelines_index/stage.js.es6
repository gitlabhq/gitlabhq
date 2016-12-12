/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueStage = Vue.extend({
    props: ['stage'],
    computed: {
      buildStatus() {
        return `Build: ${this.stage.status.label}`;
      },
      tooltip() {
        return `has-tooltip ci-status-icon-${this.stage.status.label}`;
      },
      svg() {
        return document.querySelector(`.${this.stage.status.icon}`).innerHTML;
      },
    },
    template: `
      <a
        :class='tooltip'
        :title='buildStatus'
        :href='stage.url'
        v-html='svg'
      >
      </a>
    `,
  });
})(window.gl || (window.gl = {}));
