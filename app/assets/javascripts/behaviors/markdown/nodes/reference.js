import { HIGHER_PARSE_RULE_PRIORITY } from '../constants';

// Transforms generated HTML back to GFM for Banzai::Filter::ReferenceFilter and subclasses
export default () => ({
  name: 'reference',
  schema: {
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
        priority: HIGHER_PARSE_RULE_PRIORITY,
        getAttrs: (el) => ({
          className: el.className,
          referenceType: el.dataset.referenceType,
          originalText: el.dataset.original,
          href: el.getAttribute('href'),
          text: el.textContent,
        }),
      },
    ],
    toDOM: (node) => [
      'a',
      {
        class: node.attrs.className,
        href: node.attrs.href,
        'data-reference-type': node.attrs.referenceType,
        'data-original': node.attrs.originalText,
      },
      node.attrs.text,
    ],
  },
  toMarkdown(state, node) {
    state.write(node.attrs.originalText || node.attrs.text);
  },
});
