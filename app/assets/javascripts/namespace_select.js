/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, one-var, vars-on-top, one-var-declaration-per-line, comma-dangle, object-shorthand, no-else-return, prefer-template, quotes, prefer-arrow-callback, no-param-reassign, no-cond-assign, max-len */
import Api from './api';

export default class NamespaceSelect {
  constructor(opts) {
    var fieldName, showAny;
    this.dropdown = $(opts.dropdown);
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
          return selected.kind + ": " + selected.full_path;
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
          return namespace.kind + ": " + namespace.full_path;
        }
      },
      renderRow: this.renderRow,
      clicked(options) {
        const { e } = options;
        return e.preventDefault();
      },
    });
  }
}
