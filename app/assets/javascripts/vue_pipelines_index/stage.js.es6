/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueStage = Vue.extend({
    props: ['stage'],
    computed: {
      buildStatus() {
        return `Build: ${this.stage.status}`;
      },
      tooltip() {
        return `has-tooltip ci-status-icon-${this.stage.status}`;
      },
      svg() {
        return document
          .querySelector(
            `.${this.stage.status}-icon-svg.hidden`,
          ).innerHTML;
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
