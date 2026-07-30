import { mergeAttributes } from '@tiptap/core';
import { Table } from '@tiptap/extension-table';
import { debounce } from 'lodash-es';
import { VARIANT_WARNING } from '~/alert';
import {
  STICKY_HEADER_CLASSES,
  STICKY_TABLE_WRAPPER_CLASSES,
} from '~/lib/utils/table_sticky_header';
import { __ } from '~/locale';
import { ALERT_EVENT } from '../constants';
import { getMarkdownSource } from '../services/markdown_source';
import { shouldRenderHTMLTable } from '../services/serializer/table';

export default Table.extend({
  addAttributes() {
    return {
      isMarkdown: {
        default: null,
        parseHTML: (element) => Boolean(getMarkdownSource(element)),
      },
    };
  },

  renderHTML({ HTMLAttributes }) {
    const stickyEnabled = window.gon?.features?.editorStickyTableHeaders;
    const tableEl = [
      'table',
      mergeAttributes(this.options.HTMLAttributes, HTMLAttributes),
      ['tbody', 0],
    ];

    // Outer div is needed to set the width and margin-left/margin-right of
    // .immersive .rte-text-box > *, .immersive .placeholder,
    // but keep the table inside left-aligned
    if (!stickyEnabled) {
      return ['div', {}, ['div', {}, tableEl]];
    }

    return [
      'div',
      {},
      [
        'div',
        { class: STICKY_TABLE_WRAPPER_CLASSES.join(' ') },
        [
          'div',
          {
            'data-sticky-header': true,
            class: STICKY_HEADER_CLASSES.join(' '),
          },
          tableEl,
        ],
      ],
    ];
  },

  onUpdate: debounce(function onUpdate({ editor }) {
    if (this.options.alertShown) return;

    editor.state.doc.descendants((node) => {
      if (node.type.name === 'table' && node.attrs.isMarkdown && shouldRenderHTMLTable(node)) {
        this.options.eventHub.$emit(ALERT_EVENT, {
          message: __(
            'Tables containing block elements (like multiple paragraphs, lists or blockquotes, or task lists with text or multiple items) are not supported in Markdown and will be converted to HTML.',
          ),
          variant: VARIANT_WARNING,
        });

        this.options.alertShown = true;

        return false;
      }

      return true;
    });
  }, 1000),
});
