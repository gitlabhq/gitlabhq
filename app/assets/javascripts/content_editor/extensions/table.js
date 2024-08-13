import { Table } from '@tiptap/extension-table';
import { debounce } from 'lodash';
import { VARIANT_WARNING } from '~/alert';
import { __ } from '~/locale';
import { ALERT_EVENT } from '../constants';
import { getMarkdownSource } from '../services/markdown_sourcemap';
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

  onUpdate: debounce(function onUpdate({ editor }) {
    if (this.options.alertShown) return;

    editor.state.doc.descendants((node) => {
      if (node.type.name === 'table' && node.attrs.isMarkdown && shouldRenderHTMLTable(node)) {
        this.options.eventHub.$emit(ALERT_EVENT, {
          message: __(
            'Tables containing block elements (like multiple paragraphs, lists or blockquotes) are not supported in Markdown and will be converted to HTML.',
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
