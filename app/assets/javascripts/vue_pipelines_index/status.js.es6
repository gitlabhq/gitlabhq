/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueStatusScope = Vue.extend({
    props: [
      'pipeline', 'svgs', 'match',
    ],
    computed: {
      cssClasses() {
        const cssObject = { 'ci-status': true };
        cssObject[`ci-${this.pipeline.details.status.group}`] = true;
        return cssObject;
      },
      svg() {
        return this.svgs[this.match(this.pipeline.details.status.icon)];
      },
      detailsPath() {
        const { status } = this.pipeline.details;
        return status.has_details ? status.details_path : false;
      },
    },
    template: `
      <td class="commit-link">
        <a
          :class='cssClasses'
          :href='detailsPath'
          v-html='svg + pipeline.details.status.text'
        >
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
