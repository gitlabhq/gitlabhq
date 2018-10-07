import { Node } from 'tiptap'

export default class SummaryNode extends Node {
  get name() {
    return 'summary'
  }

  get schema() {
    return {
      content: 'text*',
      marks: '',
      group: 'block',
      parseDOM: [
        { tag: 'summary' },
      ],
      toDOM: node => ['summary', 0],
    }
  }
}
