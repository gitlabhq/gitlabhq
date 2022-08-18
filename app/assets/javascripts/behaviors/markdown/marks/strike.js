// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'strike',
  schema: {
    attrs: {
      strike: {
        default: false,
      },
      inapplicable: {
        default: false,
      },
    },
    parseDOM: [
      { tag: 'li.inapplicable > s', attrs: { inapplicable: true } },
      { tag: 'li.inapplicable > p:first-of-type > s', attrs: { inapplicable: true } },
      { tag: 's', attrs: { strike: true } },
      { tag: 'del' },
    ],
    toDOM: () => ['s', 0],
  },
  toMarkdown: {
    open(_, mark) {
      if (mark.attrs.strike) {
        return '<s>';
      }
      return mark.attrs.inapplicable ? '' : '~~';
    },
    close(_, mark) {
      if (mark.attrs.strike) {
        return '</s>';
      }
      return mark.attrs.inapplicable ? '' : '~~';
    },
    mixable: true,
    expelEnclosingWhitespace: true,
  },
});
