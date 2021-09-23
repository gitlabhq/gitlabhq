import { CodeBlockLowlight } from '@tiptap/extension-code-block-lowlight';
import * as lowlight from 'lowlight';

const extractLanguage = (element) => element.getAttribute('lang');

export default CodeBlockLowlight.extend({
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
    return ['pre', HTMLAttributes, ['code', {}, 0]];
  },
}).configure({
  lowlight,
});
