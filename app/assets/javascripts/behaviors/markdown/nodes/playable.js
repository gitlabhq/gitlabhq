/* eslint-disable class-methods-use-this */
/* eslint-disable @gitlab/require-i18n-strings */

import { Node } from 'tiptap';
import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';

/**
 * Abstract base class for playable media, like video and audio.
 * Must not be instantiated directly. Subclasses must set
 * the `mediaType` property in their constructors.
 * @abstract
 */
export default class Playable extends Node {
  constructor() {
    super();
    this.mediaType = '';
    this.extraElementAttrs = {};
  }

  get name() {
    return this.mediaType;
  }

  get schema() {
    const attrs = {
      src: {},
      alt: {
        default: null,
      },
    };

    const parseDOM = [
      {
        tag: `.${this.mediaType}-container`,
        getAttrs: (el) => ({
          src: el.querySelector(this.mediaType).src,
          alt: el.querySelector(this.mediaType).dataset.title,
        }),
      },
    ];

    const toDOM = (node) => [
      'span',
      { class: `media-container ${this.mediaType}-container` },
      [
        this.mediaType,
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

    return {
      attrs,
      group: 'inline',
      inline: true,
      draggable: true,
      parseDOM,
      toDOM,
    };
  }

  toMarkdown(state, node) {
    defaultMarkdownSerializer.nodes.image(state, node);
  }
}
