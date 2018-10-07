import { Node } from 'tiptap'
import { placeholderImage } from '~/lazy_loader';

export default class VideoNode extends Node {
  get name() {
    return 'video'
  }

  get schema() {
    return {
      attrs: {
        src: {},
        alt: {
          default: null,
        },
      },
      group: 'block',
      draggable: true,
      parseDOM: [
        {
          tag: '.video-container',
          skip: true
        },
        {
          tag: '.video-container p',
          priority: 51,
          ignore: true
        },
        {
          tag: 'video[src]',
          getAttrs: el => ({ src: el.getAttribute('src'), alt: el.dataset.title }),
        },
      ],
      toDOM: node => [
        'video',
        {
          src: node.attrs.src,
          width: '400',
          controls: true,
          'data-setup': '{}',
          'data-title': node.attrs.alt
        }
      ],
    }
  }
}
