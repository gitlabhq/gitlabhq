import { Node } from '@tiptap/core';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import PlayableWrapper from '../components/wrappers/playable.vue';
import { getSourceMapAttributes } from '../services/markdown_sourcemap';

const queryPlayableElement = (element, mediaType) => element.querySelector(mediaType);

export default Node.create({
  group: 'inline',
  inline: true,
  draggable: true,

  addAttributes() {
    return {
      uploading: {
        default: false,
      },
      src: {
        default: null,
        parseHTML: (element) => queryPlayableElement(element, this.options.mediaType).src,
      },
      canonicalSrc: {
        default: null,
        parseHTML: (element) =>
          queryPlayableElement(element, this.options.mediaType).dataset.canonicalSrc,
      },
      alt: {
        default: null,
        parseHTML: (element) => queryPlayableElement(element, this.options.mediaType).dataset.title,
      },
      width: {
        default: null,
        parseHTML: (element) =>
          queryPlayableElement(element, this.options.mediaType).getAttribute('width'),
      },
      height: {
        default: null,
        parseHTML: (element) =>
          queryPlayableElement(element, this.options.mediaType).getAttribute('height'),
      },
      ...getSourceMapAttributes((element) => queryPlayableElement(element, this.options.mediaType)),
    };
  },

  parseHTML() {
    return [
      {
        tag: `.${this.options.mediaType}-container`, // eslint-disable-line @gitlab/require-i18n-strings
      },
    ];
  },

  renderHTML({ node }) {
    return [
      'span',
      { class: `media-container ${this.options.mediaType}-container` },
      [
        this.options.mediaType,
        {
          src: node.attrs.src,
          controls: true,
          'data-setup': '{}',
          'data-title': node.attrs.alt,
        },
      ],
      [
        'a',
        { href: node.attrs.src, class: 'with-attachment-icon' },
        node.attrs.title || node.attrs.alt || '',
      ],
    ];
  },

  addNodeView() {
    return VueNodeViewRenderer(PlayableWrapper);
  },
});
