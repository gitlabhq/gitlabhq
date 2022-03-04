// Transforms generated HTML back to GFM for Banzai::Filter::InlineDiffFilter
export default () => ({
  name: 'inline_diff',
  schema: {
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
  },
  toMarkdown: {
    mixable: true,
    open(_, mark) {
      return mark.attrs.addition ? '{+' : '{-';
    },
    close(_, mark) {
      return mark.attrs.addition ? '+}' : '-}';
    },
  },
});
