import { Mark } from 'tiptap'
import { toggleMark, markInputRule } from 'tiptap-commands'

export default class MathMark extends Mark {
  get name() {
    return 'math'
  }

  get schema() {
    return {
      parseDOM: [
        {
          tag: 'code.code.math[data-math-style=inline]',
          priority: 51
        },
        { tag: 'span.katex', contentElement: 'annotation[encoding="application/x-tex"]' }
      ],
      toDOM: () => ['code', { class: 'code math', 'data-math-style': 'inline' }, 0],
    }
  }

  command({ type }) {
    return toggleMark(type)
  }

  inputRules({ type }) {
    return [
      markInputRule(/(?:\$`)([^`]+)(?:`\$)$/, type),
    ]
  }
}
