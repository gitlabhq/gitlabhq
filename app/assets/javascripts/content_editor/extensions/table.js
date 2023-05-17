import { Table } from '@tiptap/extension-table';
import { debounce } from 'lodash';
import { VARIANT_WARNING } from '~/alert';
import { __ } from '~/locale';
import { getMarkdownSource } from '../services/markdown_sourcemap';
import { shouldRenderHTMLTable } from '../services/serialization_helpers';

let alertShown = false;
const onUpdate = debounce((editor) => {
  if (alertShown) return;

  editor.state.doc.descendants((node) => {
    if (node.type.name === 'table' && node.attrs.isMarkdown && shouldRenderHTMLTable(node)) {
      editor.emit('alert', {
        message: __(
          'The content editor may change the markdown formatting style of the document, which may not match your original markdown style.',
        ),
        variant: VARIANT_WARNING,
      });

      alertShown = true;

      return false;
    }

    return true;
  });
}, 1000);

export default Table.extend({
  addAttributes() {
    return {
      isMarkdown: {
        default: null,
        parseHTML: (element) => Boolean(getMarkdownSource(element)),
      },
    };
  },

  onUpdate({ editor }) {
    onUpdate(editor);
  },
});
