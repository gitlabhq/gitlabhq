import { Node } from 'tiptap'

export default class EmojiNode extends Node {
  get name() {
    return 'emoji'
  }

  get schema() {
    return {
      inline: true,
      group: 'inline',
      attrs: {
        name: {},
        title: {},
        moji: {}
      },
      parseDOM: [
        {
          tag: 'gl-emoji',
          getAttrs: el => ({ name: el.dataset.name, title: el.getAttribute('title'), moji: el.textContent }),
        },
      ],
      toDOM: node => ['gl-emoji', { 'data-name': node.attrs.name, title: node.attrs.title }, node.attrs.moji],
    }
  }
}
