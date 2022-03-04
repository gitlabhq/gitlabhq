// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'strike',
  schema: {
    parseDOM: [
      {
        tag: 'del',
      },
    ],
    toDOM: () => ['s', 0],
  },
  toMarkdown: {
    open: '~~',
    close: '~~',
    mixable: true,
    expelEnclosingWhitespace: true,
  },
});
