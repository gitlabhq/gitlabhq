import { Node } from 'tiptap'
import { placeholderImage } from '~/lazy_loader';

export default class ImageNode extends Node {

  get name() {
    return 'image'
  }

  get schema() {
    return {
      inline: true,
      attrs: {
        src: {},
        alt: {
          default: null,
        },
        title: {
          default: null,
        },
      },
      group: 'inline',
      draggable: true,
      parseDOM: [
        {
          tag: 'a.no-attachment-icon',
          priority: 51,
          skip: true
        },
        {
          tag: 'img[src]',
          getAttrs: el => {
            const imageSrc = el.src;
            const imageUrl = imageSrc && imageSrc !== placeholderImage ? imageSrc : (el.dataset.src || '');

            return {
              src: imageUrl,
              title: el.getAttribute('title'),
              alt: el.getAttribute('alt'),
            };
          },
        },
      ],
      toDOM: node => ['img', node.attrs],
    }
  }

  command({ type, attrs }) {
    return (state, dispatch) => {
      const { selection } = state
      const position = selection.$cursor ? selection.$cursor.pos : selection.$to.pos
      const node = type.create(attrs)
      const transaction = state.tr.insert(position, node)
      dispatch(transaction)
    }
  }
}
