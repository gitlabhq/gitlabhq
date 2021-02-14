import $ from 'jquery';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import { parseBoolean } from '~/lib/utils/common_utils';
import Api from './api';
import { mergeUrlParams } from './lib/utils/url_utility';
import { __ } from './locale';

export default class NamespaceSelect {
  constructor(opts) {
    const isFilter = parseBoolean(opts.dropdown.dataset.isFilter);
    const fieldName = opts.dropdown.dataset.fieldName || 'namespace_id';

    initDeprecatedJQueryDropdown($(opts.dropdown), {
      filterable: true,
      selectable: true,
      filterRemote: true,
      search: {
        fields: ['path'],
      },
      fieldName,
      toggleLabel(selected) {
        if (selected.id == null) {
          return selected.text;
        }
        return `${selected.kind}: ${selected.full_path}`;
      },
      data(term, dataCallback) {
        return Api.namespaces(term, (namespaces) => {
          if (isFilter) {
            const anyNamespace = {
              text: __('Any namespace'),
              id: null,
            };
            namespaces.unshift(anyNamespace);
            namespaces.splice(1, 0, { type: 'divider' });
          }
          return dataCallback(namespaces);
        });
      },
      text(namespace) {
        if (namespace.id == null) {
          return namespace.text;
        }
        return `${namespace.kind}: ${namespace.full_path}`;
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
