/* eslint-disable func-names, space-before-function-paren, no-var, comma-dangle, object-shorthand, no-else-return, prefer-template, quotes, prefer-arrow-callback, max-len */

import $ from 'jquery';
import Api from './api';
import { mergeUrlParams } from './lib/utils/url_utility';

export default class NamespaceSelect {
  constructor(opts) {
    const isFilter = opts.dropdown.dataset.isFilter === 'true';
    const fieldName = opts.dropdown.dataset.fieldName || 'namespace_id';

    $(opts.dropdown).glDropdown({
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
          if (isFilter) {
            const anyNamespace = {
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
        if (!isFilter) {
          const { e } = options;
          e.preventDefault();
        }
      },
      url(namespace) {
        return mergeUrlParams({ [fieldName]: namespace.id }, window.location.href);
      },
    });
  }
}
