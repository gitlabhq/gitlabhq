import { escape } from 'lodash';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'inline_html',
  schema: {
    excludes: '',
    attrs: {
      tag: {},
      title: { default: null },
    },
    parseDOM: [
      {
        tag: 'sup, sub, kbd, q, samp, var',
        getAttrs: (el) => ({ tag: el.nodeName.toLowerCase() }),
      },
      {
        tag: 'abbr',
        getAttrs: (el) => ({ tag: 'abbr', title: el.getAttribute('title') }),
      },
    ],
    toDOM: (node) => [node.attrs.tag, { title: node.attrs.title }, 0],
  },
  toMarkdown: {
    mixable: true,
    open(state, mark) {
      return `<${mark.attrs.tag}${
        mark.attrs.title ? ` title="${state.esc(escape(mark.attrs.title))}"` : ''
      }>`;
    },
    close(_, mark) {
      return `</${mark.attrs.tag}>`;
    },
  },
});
