import { CodeBlockLowlight } from '@tiptap/extension-code-block-lowlight';
import * as lowlight from 'lowlight';

const extractLanguage = (element) => element.getAttribute('lang');

export default CodeBlockLowlight.extend({
  addAttributes() {
    return {
      language: {
        default: null,
        parseHTML: (element) => {
          return {
            language: extractLanguage(element),
          };
        },
      },
      class: {
        default: 'code highlight js-syntax-highlight',
      },
    };
  },
  renderHTML({ HTMLAttributes }) {
    return ['pre', HTMLAttributes, ['code', {}, 0]];
  },
}).configure({
  lowlight,
});
