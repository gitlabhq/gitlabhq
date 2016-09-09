(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.TemplateSelector = (function() {
    function TemplateSelector(opts) {
      var ref;
      if (opts == null) {
        opts = {};
      }
      this.onClick = bind(this.onClick, this);
      this.dropdown = opts.dropdown, this.data = opts.data, this.pattern = opts.pattern, this.wrapper = opts.wrapper, this.editor = opts.editor, this.fileEndpoint = opts.fileEndpoint, this.$input = (ref = opts.$input) != null ? ref : $('#file_name');
      this.dropdownIcon = $('.fa-chevron-down', this.dropdown);
      this.buildDropdown();
      this.bindEvents();
      this.onFilenameUpdate();
    }

    TemplateSelector.prototype.buildDropdown = function() {
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
    };

    TemplateSelector.prototype.bindEvents = function() {
      return this.$input.on('keyup blur', (function(_this) {
        return function(e) {
          return _this.onFilenameUpdate();
        };
      })(this));
    };

    TemplateSelector.prototype.toggleLabel = function(item) {
      return item.name;
    };

    TemplateSelector.prototype.onFilenameUpdate = function() {
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
    };

    TemplateSelector.prototype.onClick = function(item, el, e) {
      e.preventDefault();
      return this.requestFile(item);
    };

    TemplateSelector.prototype.requestFile = function(item) {
      // This `requestFile` method is an abstract method that should
      // be added by all subclasses.
    };

    // To be implemented on the extending class
    // e.g.
    // Api.gitignoreText item.name, @requestFileSuccess.bind(@)
    TemplateSelector.prototype.requestFileSuccess = function(file, skipFocus) {
      this.editor.setValue(file.content, 1);
      if (!skipFocus) this.editor.focus();
    };

    TemplateSelector.prototype.startLoadingSpinner = function() {
      this.dropdownIcon
        .addClass('fa-spinner fa-spin')
        .removeClass('fa-chevron-down');
    };

    TemplateSelector.prototype.stopLoadingSpinner = function() {
      this.dropdownIcon
        .addClass('fa-chevron-down')
        .removeClass('fa-spinner fa-spin');
    };

    return TemplateSelector;

  })();

}).call(this);
