/* global Vue */
(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.ModalSearch = Vue.extend({
    template: `
      <input
        placeholder="Search issues..."
        class="form-control"
        type="search" />
    `,
  });
})();
