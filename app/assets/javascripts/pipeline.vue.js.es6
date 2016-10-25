//= require vue

(gl => {
  gl.VuePipeLine = Vue.extend({
    props: ['pipeline'],
    template: `
      <div>
        <td>
          {{ pipeline.status }}
        </td>
      </div>
    `
  })
})(window.gl || (window.gl = {}))
