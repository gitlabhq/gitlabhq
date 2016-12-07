/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueStatusScope = Vue.extend({
    props: [
      'pipeline',
    ],
    computed: {
      cssClasses() {
        const cssObject = {};
        cssObject['ci-status'] = true;
        cssObject[`ci-${this.pipeline.details.status.text}`] = true;
        return cssObject;
      },
      svg() {
        return document
          .querySelector(
            `.${this.pipeline.details.status.text}-icon-svg.hidden`,
          ).innerHTML;
      },
    },
    template: `
      <td class="commit-link">
        <a :href='pipeline.url'>
          <span :class='cssClasses'>
            <span v-html='svg'></span>
            <span>&nbsp;{{pipeline.details.status.text}}</span>
          </span>
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
