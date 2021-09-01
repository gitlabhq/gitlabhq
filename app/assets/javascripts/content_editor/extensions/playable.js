/* eslint-disable @gitlab/require-i18n-strings */

import { Node } from '@tiptap/core';

const queryPlayableElement = (element, mediaType) => element.querySelector(mediaType);

export default Node.create({
  group: 'inline',
  inline: true,
  draggable: true,

  addAttributes() {
    return {
      src: {
        default: null,
        parseHTML: (element) => {
          const playable = queryPlayableElement(element, this.options.mediaType);

          return {
            src: playable.src,
          };
        },
      },
      canonicalSrc: {
        default: null,
        parseHTML: (element) => {
          const playable = queryPlayableElement(element, this.options.mediaType);

          return {
            canonicalSrc: playable.dataset.canonicalSrc,
          };
        },
      },
      alt: {
        default: null,
        parseHTML: (element) => {
          const playable = queryPlayableElement(element, this.options.mediaType);

          return {
            alt: playable.dataset.title,
          };
        },
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: `.${this.options.mediaType}-container`,
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
          ...this.extraElementAttrs,
        },
      ],
      ['a', { href: node.attrs.src }, node.attrs.alt],
    ];
  },
});
