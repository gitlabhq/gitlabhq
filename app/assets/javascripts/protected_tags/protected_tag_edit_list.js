/* eslint-disable arrow-parens, no-param-reassign, no-new, comma-dangle */

(global => {
  global.gl = global.gl || {};

  gl.ProtectedTagEditList = class {
    constructor() {
      this.$wrap = $('.protected-tags-list');

      // Build edit forms
      this.$wrap.find('.js-protected-tag-edit-form').each((i, el) => {
        new gl.ProtectedTagEdit({
          $wrap: $(el)
        });
      });
    }
  };
})(window);
