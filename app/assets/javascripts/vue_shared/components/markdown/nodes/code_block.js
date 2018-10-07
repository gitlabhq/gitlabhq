import { Node } from 'tiptap'
import { toggleBlockType, setBlockType, textblockTypeInputRule } from 'tiptap-commands'

export default class CodeBlockNode extends Node {
  get name() {
    return 'code_block'
  }

  get schema() {
    return {
      content: 'text*',
      marks: '',
      group: 'block',
      code: true,
      defining: true,
      draggable: false,
      attrs: {
        lang: { default: '' }
      },
      parseDOM: [
        {
          tag: 'pre.code.highlight',
          preserveWhitespace: 'full',
          getAttrs: (el) => {
            let lang = el.getAttribute('lang');
            if (!lang || lang == 'plaintext') lang = '';

            return { lang };
          }
        },
        {
          tag: 'span.katex-display',
          preserveWhitespace: 'full',
          contentElement: 'annotation[encoding="application/x-tex"]',
          attrs: { lang: 'math' }
        },
        {
          tag: 'svg.mermaid',
          preserveWhitespace: 'full',
          contentElement: 'text.source',
          attrs: { lang: 'mermaid' }
        }
      ],
      toDOM: node => ['pre', { class: 'code highlight', lang: node.attrs.lang }, ['code', 0]],
    }
  }

  command({ type, schema }) {
    return toggleBlockType(type, schema.nodes.paragraph)
  }

  keys({ type }) {
    return {
      'Shift-Ctrl-\\': setBlockType(type),
    }
  }

  inputRules({ type }) {
    return [
      textblockTypeInputRule(/^```$/, type),
    ]
  }
}
