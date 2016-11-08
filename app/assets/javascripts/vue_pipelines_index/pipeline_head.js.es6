/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VuePipelineHead = Vue.extend({
    template: `
      <thead>
        <tr>
          <th>Status</th>
          <th>Pipeline</th>
          <th>Commit</th>
          <th>Stages</th>
          <th></th>
          <th class="hidden-xs"></th>
        </tr>
      </thead>
    `,
  });
})(window.gl || (window.gl = {}));
