(global => {
  global.gl = global.gl || {};

  gl.NoteTemplateDropdownsCreate = class {
    constructor() {
      this.buildDropdowns();
    }

    buildDropdowns() {
      $('.js-note-template-btn').each(function() {
        new NoteTemplateDropdown({
          $dropdown: $(this)
        });
      });      
    }
  }

})(window);
