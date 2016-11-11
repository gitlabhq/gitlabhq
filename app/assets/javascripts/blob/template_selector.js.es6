/* eslint-disable */
((global) => {
    class TemplateSelector {
      constructor({ dropdown, data, pattern, wrapper, editor, fileEndpoint, $input } = {}) {
        this.onClick = this.onClick.bind(this);
        this.dropdown = dropdown;
        this.data = data;
        this.pattern = pattern;
        this.wrapper = wrapper;
        this.editor = editor;
        this.fileEndpoint = fileEndpoint;
        this.$input = $input || $('#file_name');
        this.dropdownIcon = $('.fa-chevron-down', this.dropdown);
        this.buildDropdown();
        this.bindEvents();
        this.onFilenameUpdate();

        this.autosizeUpdateEvent = document.createEvent('Event');
        this.autosizeUpdateEvent.initEvent('autosize:update', true, false);
      }

      buildDropdown() {
        return this.dropdown.glDropdown({
          data: this.data,
          filterable: true,
          selectable: true,
          toggleLabel: this.toggleLabel,
          search: {
            fields: ['name']
          },
          clicked: this.onClick,
          text: function(item) {
            return item.name;
          }
        });
      }

      bindEvents() {
        return this.$input.on('keyup blur', (e) => this.onFilenameUpdate());
      }

      toggleLabel(item) {
        return item.name;
      }

      onFilenameUpdate() {
        var filenameMatches;
        if (!this.$input.length) {
          return;
        }
        filenameMatches = this.pattern.test(this.$input.val().trim());
        if (!filenameMatches) {
          this.wrapper.addClass('hidden');
          return;
        }
        return this.wrapper.removeClass('hidden');
      }

      onClick(item, el, e) {
        e.preventDefault();
        return this.requestFile(item);
      }

      requestFile(item) {
        // This `requestFile` method is an abstract method that should
        // be added by all subclasses.
      }

      // To be implemented on the extending class
      // e.g.
      // Api.gitignoreText item.name, @requestFileSuccess.bind(@)
      requestFileSuccess(file, { skipFocus } = {}) {
        const oldValue = this.editor.getValue();
        let newValue = file.content;

        this.editor.setValue(newValue, 1);
        if (!skipFocus) this.editor.focus();

        if (this.editor instanceof jQuery) {
          this.editor.get(0).dispatchEvent(this.autosizeUpdateEvent);
        }
      }

      startLoadingSpinner() {
        this.dropdownIcon
          .addClass('fa-spinner fa-spin')
          .removeClass('fa-chevron-down');
      }

      stopLoadingSpinner() {
        this.dropdownIcon
          .addClass('fa-chevron-down')
          .removeClass('fa-spinner fa-spin');
      }
    }

    global.TemplateSelector = TemplateSelector;
  })(window.gl || ( window.gl = {}));
