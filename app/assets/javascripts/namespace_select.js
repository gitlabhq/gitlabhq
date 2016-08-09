(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.NamespaceSelect = (function() {
    function NamespaceSelect(opts) {
      this.onSelectItem = bind(this.onSelectItem, this);
      var fieldName, showAny;
      this.dropdown = opts.dropdown;
      showAny = true;
      fieldName = 'namespace_id';
      if (this.dropdown.attr('data-field-name')) {
        fieldName = this.dropdown.data('fieldName');
      }
      if (this.dropdown.attr('data-show-any')) {
        showAny = this.dropdown.data('showAny');
      }
      this.dropdown.glDropdown({
        filterable: true,
        selectable: true,
        filterRemote: true,
        search: {
          fields: ['path']
        },
        fieldName: fieldName,
        toggleLabel: function(selected) {
          if (selected.id == null) {
            return selected.text;
          } else {
            return selected.kind + ": " + selected.path;
          }
        },
        data: function(term, dataCallback) {
          return Api.namespaces(term, function(namespaces) {
            var anyNamespace;
            if (showAny) {
              anyNamespace = {
                text: 'Any namespace',
                id: null
              };
              namespaces.unshift(anyNamespace);
              namespaces.splice(1, 0, 'divider');
            }
            return dataCallback(namespaces);
          });
        },
        text: function(namespace) {
          if (namespace.id == null) {
            return namespace.text;
          } else {
            return namespace.kind + ": " + namespace.path;
          }
        },
        renderRow: this.renderRow,
        clicked: this.onSelectItem
      });
    }

    NamespaceSelect.prototype.onSelectItem = function(item, el, e) {
      return e.preventDefault();
    };

    return NamespaceSelect;

  })();

  this.NamespaceSelects = (function() {
    function NamespaceSelects(opts) {
      var ref;
      if (opts == null) {
        opts = {};
      }
      this.$dropdowns = (ref = opts.$dropdowns) != null ? ref : $('.js-namespace-select');
      this.$dropdowns.each(function(i, dropdown) {
        var $dropdown;
        $dropdown = $(dropdown);
        return new NamespaceSelect({
          dropdown: $dropdown
        });
      });
    }

    return NamespaceSelects;

  })();

}).call(this);
