import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'link',
  schema: {
    attrs: {
      href: {
        default: null,
      },
      target: {
        default: null,
      },
    },
    inclusive: false,
    parseDOM: [
      {
        tag: 'a[href]',
        getAttrs: (dom) => ({
          href: dom.getAttribute('href'),
          target: dom.getAttribute('target'),
        }),
      },
    ],
    toDOM: (node) => [
      'a',
      {
        ...node.attrs,
        // eslint-disable-next-line @gitlab/require-i18n-strings
        rel: 'noopener noreferrer nofollow',
        target: node.attrs.target,
      },
      0,
    ],
  },
  toMarkdown: {
    mixable: true,
    open(state, mark, parent, index) {
      const open = defaultMarkdownSerializer.marks.link.open(state, mark, parent, index);
      return open === '<' ? '' : open;
    },
    close(state, mark, parent, index) {
      const close = defaultMarkdownSerializer.marks.link.close(state, mark, parent, index);
      return close === '>' ? '' : close;
    },
  },
});
