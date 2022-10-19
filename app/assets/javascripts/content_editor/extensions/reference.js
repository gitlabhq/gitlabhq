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
        parseHTML: (element) => getAnchor(element).className,
      },
      referenceType: {
        default: null,
        parseHTML: (element) => getAnchor(element).dataset.referenceType,
      },
      originalText: {
        default: null,
        parseHTML: (element) => getAnchor(element).dataset.original,
      },
      href: {
        default: null,
        parseHTML: (element) => getAnchor(element).getAttribute('href'),
      },
      text: {
        default: null,
        parseHTML: (element) => getAnchor(element).textContent,
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'a.gfm:not([data-link=true])',
        priority: PARSE_HTML_PRIORITY_HIGHEST,
      },
    ];
  },

  renderHTML({ node }) {
    return ['a', { href: '#' }, node.attrs.text];
  },
});
