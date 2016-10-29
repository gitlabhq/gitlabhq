//= require vue
/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueRunnerStatus = Vue.extend({
    props: ['status'],
    template: `
      <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
        <g fill={{status.color}} fill-rule="evenodd">
          <path d={{status.pathOne}}></path>
          <path d={{status.pathTwo}}></path>
        </g>
      </svg>
      &nbsp;{{status.text}}
    `,
  });
})(window.gl || (window.gl = {}));
