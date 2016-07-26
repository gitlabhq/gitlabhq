((global) => {
  class TemplateSelector {
    constructor(opts = {}) {
      this.dropdown = opts.dropdown;
      this.data = opts.data;
      this.pattern = opts.pattern;
      this.wrapper = opts.wrapper;
      this.editor = opts.editor;
      this.fileEndpoint = opts.fileEndpoint;
      this.$input = opts.$input || $('#file_name');

      this.buildDropdown();
      this.bindEvents();
      this.onFilenameUpdate();
    }

    buildDropdown() {
      this.dropdown.glDropdown({
        data: this.data,
        filterable: true,
        selectable: true,
        search: {
          fields: ['name']
        },
        clicked: this.onClick,
        text: (item) => {
          return item.name;
        }
      });
    }

    bindEvents() {
      this.$input.on('keyup blur', () => {
        this.onFilenameUpdate();
      });
    }

    onFilenameUpdate() {
      if (!this.input.length) return;

      let filenameMatches = this.pattern.test(this.$input.val().trim());

      if (!filenameMatches) {
        this.wrapper.addClass('hidden');
        return;
      }

      this.wrapper.removeClass('hidden');
    }

    onClick(item, el, e) {
      e.preventDefault();
      this.requestFile(item);
    }

    requestFile(item) {
      // To be implemented on the extending class
      // e.g.
      // Api.gitignoreText(item.name, this.requestFileSuccess.bind(this));
    }

    requestFileSuccess(file) {
      this.editor.setValue(file.content, 1);
      this.editor.focus();
    }
  }

  global.TemplateSelector = TemplateSelector;
})(window);
