// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'ordered_list',
  schema: {
    attrs: {
      order: {
        default: 1,
      },
    },
    content: 'list_item+',
    group: 'block',
    parseDOM: [
      {
        tag: 'ol',
        getAttrs: (dom) => ({
          order: dom.hasAttribute('start') ? dom.getAttribute('start') + 1 : 1,
        }),
      },
    ],
    toDOM: (node) => (node.attrs.order === 1 ? ['ol', 0] : ['ol', { start: node.attrs.order }, 0]),
  },
  toMarkdown(state, node) {
    state.renderList(node, '   ', () => '1. ');
  },
});
