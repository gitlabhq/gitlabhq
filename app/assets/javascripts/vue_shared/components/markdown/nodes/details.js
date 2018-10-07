import { Node } from 'tiptap'

export default class DetailsNode extends Node {
  get name() {
    return 'details'
  }

  get schema() {
    return {
      content: 'summary block*',
      group: 'block',
      defining: true,
      draggable: false,
      parseDOM: [
        { tag: 'details' },
      ],
      toDOM: node => ['details', { open: true, onclick: 'return false', tabindex: '-1' }, 0],
    }
  }
}
