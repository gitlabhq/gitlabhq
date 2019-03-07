/* eslint-disable class-methods-use-this */

import { Node } from 'tiptap';

// Transforms generated HTML back to GFM for Banzai::Filter::ReferenceFilter and subclasses
export default class Reference extends Node {
  get name() {
    return 'reference';
  }

  get schema() {
    return {
      inline: true,
      group: 'inline',
      atom: true,
      attrs: {
        className: {},
        referenceType: {},
        originalText: { default: null },
        href: {},
        text: {},
      },
      parseDOM: [
        {
          tag: 'a.gfm:not([data-link=true])',
          priority: 51,
          getAttrs: el => ({
            className: el.className,
            referenceType: el.dataset.referenceType,
            originalText: el.dataset.original,
            href: el.getAttribute('href'),
            text: el.textContent,
          }),
        },
      ],
      toDOM: node => [
        'a',
        {
          class: node.attrs.className,
          href: node.attrs.href,
          'data-reference-type': node.attrs.referenceType,
          'data-original': node.attrs.originalText,
        },
        node.attrs.text,
      ],
    };
  }

  toMarkdown(state, node) {
    state.write(node.attrs.originalText || node.attrs.text);
  }
}
