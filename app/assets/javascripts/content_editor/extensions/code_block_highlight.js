import { CodeBlockLowlight } from '@tiptap/extension-code-block-lowlight';
import { lowlight } from 'lowlight/lib/all';

const extractLanguage = (element) => element.getAttribute('lang');

export default CodeBlockLowlight.extend({
  isolating: true,

  addAttributes() {
    return {
      language: {
        default: null,
        parseHTML: (element) => extractLanguage(element),
      },
      class: {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        default: 'code highlight',
      },
    };
  },
  renderHTML({ HTMLAttributes }) {
    return [
      'pre',
      {
        ...HTMLAttributes,
        class: `content-editor-code-block ${HTMLAttributes.class}`,
      },
      ['code', {}, 0],
    ];
  },
}).configure({
  lowlight,
});
