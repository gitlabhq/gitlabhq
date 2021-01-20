/* eslint-disable class-methods-use-this */

import { Mark } from 'tiptap';

// Transforms generated HTML back to GFM for Banzai::Filter::InlineDiffFilter
export default class InlineDiff extends Mark {
  get name() {
    return 'inline_diff';
  }

  get schema() {
    return {
      attrs: {
        addition: {
          default: true,
        },
      },
      parseDOM: [
        { tag: 'span.idiff.addition', attrs: { addition: true } },
        { tag: 'span.idiff.deletion', attrs: { addition: false } },
      ],
      toDOM: (node) => [
        'span',
        { class: `idiff left right ${node.attrs.addition ? 'addition' : 'deletion'}` },
        0,
      ],
    };
  }

  get toMarkdown() {
    return {
      mixable: true,
      open(state, mark) {
        return mark.attrs.addition ? '{+' : '{-';
      },
      close(state, mark) {
        return mark.attrs.addition ? '+}' : '-}';
      },
    };
  }
}
