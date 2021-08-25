import { Node } from '@tiptap/core';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

const getAnchor = (element) => {
  if (element.nodeName === 'A') return element;
  return element.querySelector('a');
};

export default Node.create({
  name: 'reference',

  inline: true,

  group: 'inline',

  atom: true,

  addAttributes() {
    return {
      className: {
        default: null,
        parseHTML: (element) => {
          return {
            className: getAnchor(element).className,
          };
        },
      },
      referenceType: {
        default: null,
        parseHTML: (element) => {
          return {
            referenceType: getAnchor(element).dataset.referenceType,
          };
        },
      },
      originalText: {
        default: null,
        parseHTML: (element) => {
          return {
            originalText: getAnchor(element).dataset.original,
          };
        },
      },
      href: {
        default: null,
        parseHTML: (element) => {
          return {
            href: getAnchor(element).getAttribute('href'),
          };
        },
      },
      text: {
        default: null,
        parseHTML: (element) => {
          return {
            text: getAnchor(element).textContent,
          };
        },
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'a.gfm:not([data-link=true])',
        priority: PARSE_HTML_PRIORITY_HIGHEST,
      },
      {
        tag: 'span.gl-label',
      },
    ];
  },

  renderHTML({ node }) {
    return [
      'a',
      {
        class: node.attrs.className,
        href: node.attrs.href,
        'data-reference-type': node.attrs.referenceType,
        'data-original': node.attrs.originalText,
      },
      node.attrs.text,
    ];
  },
});
