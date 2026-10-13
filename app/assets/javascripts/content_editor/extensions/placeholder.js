import { Node } from '@tiptap/core';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';
import PlaceholderWrapper from '../components/wrappers/placeholder.vue';

const PLACEHOLDER_REGEX = /^%\{[\p{Alphabetic}\p{M}\p{Pc}\p{Nd}\p{Join_Control}]{1,30}\}$/u;

const isPlaceholder = (element) => {
  const [child, ...rest] = element.childNodes;

  if (rest.length > 0 || (child && child.nodeType !== window.Node.TEXT_NODE)) return false;

  return PLACEHOLDER_REGEX.test(element.dataset.placeholder || element.textContent);
};

export default Node.create({
  name: 'placeholder',
  inline: true,
  group: 'inline',

  addAttributes() {
    return {
      placeholder: {
        default: null,
        parseHTML: (element) => element.dataset.placeholder || element.textContent,
      },
      value: {
        default: null,
        parseHTML: (element) => (element.dataset.placeholder && element.textContent) || null,
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'span[data-placeholder]',
        priority: PARSE_HTML_PRIORITY_HIGHEST,
        getAttrs: (element) => (isPlaceholder(element) ? null : false),
      },
    ];
  },

  renderHTML({ node }) {
    const { placeholder, value } = node.attrs;

    return value
      ? ['span', { 'data-placeholder': placeholder }, value]
      : ['span', { 'data-placeholder': '' }, placeholder];
  },

  addNodeView() {
    return VueNodeViewRenderer(PlaceholderWrapper);
  },
});
