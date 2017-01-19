/* eslint-disable arrow-parens, no-param-reassign, no-irregular-whitespace, no-new, comma-dangle, semi, padded-blocks, max-len */

(global => {
  global.gl = global.gl || {};

  gl.ProtectedBranchEditList = class {
    constructor() {
      this.$wrap = $('.protected-branches-list');

      // Build edit forms
      this.$wrap.find('.js-protected-branch-edit-form').each((i, el) => {
        new gl.ProtectedBranchEdit({
          $wrap: $(el)
        });
      });
    }
  }

})(window);
