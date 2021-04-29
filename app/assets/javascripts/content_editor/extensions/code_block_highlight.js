import { CodeBlockLowlight } from '@tiptap/extension-code-block-lowlight';

const extractLanguage = (element) => element.firstElementChild?.getAttribute('lang');

export default CodeBlockLowlight.extend({
  addAttributes() {
    return {
      ...this.parent(),
      /* `params` is the name of the attribute that
        prosemirror-markdown uses to extract the language
        of a codeblock.
        https://github.com/ProseMirror/prosemirror-markdown/blob/master/src/to_markdown.js#L62
      */
      params: {
        parseHTML: (element) => {
          return {
            params: extractLanguage(element),
          };
        },
      },
    };
  },
});
