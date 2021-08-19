import { Node } from '@tiptap/core';

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
            className: element.className,
          };
        },
      },
      referenceType: {
        default: null,
        parseHTML: (element) => {
          return {
            referenceType: element.dataset.referenceType,
          };
        },
      },
      originalText: {
        default: null,
        parseHTML: (element) => {
          return {
            originalText: element.dataset.original,
          };
        },
      },
      href: {
        default: null,
        parseHTML: (element) => {
          return {
            href: element.getAttribute('href'),
          };
        },
      },
      text: {
        default: null,
        parseHTML: (element) => {
          return {
            text: element.textContent,
          };
        },
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'a.gfm:not([data-link=true])',
        priority: 51,
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
