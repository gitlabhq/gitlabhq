import { Mark } from 'tiptap'
import { toggleMark, markInputRule } from 'tiptap-commands'

const tags = 'sup sub kbd q samp var'.split(' ');

export default class InlineHTMLMark extends Mark {
  get name() {
    return 'inline_html'
  }

  get schema() {
    return {
      excludes: '',
      attrs: {
        tag: {},
        title: { default: null }
      },
      parseDOM: [
        {
          tag: tags.join(', '),
          getAttrs: (el) => ({ tag: el.nodeName.toLowerCase() })
        },
        {
          tag: 'abbr',
          getAttrs: (el) => ({ tag: 'abbr', title: el.getAttribute('title') })
        },
      ],
      toDOM: node => [node.attrs.tag, { title: node.attrs.title }, 0],
    }
  }

  command({ type }) {
    return toggleMark(type)
  }

  inputRules({ type }) {
    return tags.map(tag =>
      markInputRule(new RegExp(`(?:\\<${tag}\\>)([^\\<]+)(?:\\<\\/${tag}\\>)$`), type, { tag })
    );
  }
}
