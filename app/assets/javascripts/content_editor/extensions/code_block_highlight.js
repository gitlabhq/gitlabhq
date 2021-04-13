import { CodeBlockHighlight as BaseCodeBlockHighlight } from 'tiptap-extensions';

export default class GlCodeBlockHighlight extends BaseCodeBlockHighlight {
  get schema() {
    const baseSchema = super.schema;

    return {
      ...baseSchema,
      attrs: {
        params: {
          default: null,
        },
      },
      parseDOM: [
        {
          tag: 'pre',
          preserveWhitespace: 'full',
          getAttrs: (node) => {
            const code = node.querySelector('code');

            if (!code) {
              return null;
            }

            return {
              /* `params` is the name of the attribute that
                prosemirror-markdown uses to extract the language
                of a codeblock.
                https://github.com/ProseMirror/prosemirror-markdown/blob/master/src/to_markdown.js#L62
              */
              params: code.getAttribute('lang'),
            };
          },
        },
      ],
    };
  }
}
