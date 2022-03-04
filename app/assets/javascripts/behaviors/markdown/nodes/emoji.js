// Transforms generated HTML back to GFM for Banzai::Filter::EmojiFilter
export default () => ({
  name: 'emoji',
  schema: {
    inline: true,
    group: 'inline',
    attrs: {
      name: {},
      title: {},
      moji: {},
    },
    parseDOM: [
      {
        tag: 'gl-emoji',
        getAttrs: (el) => ({
          name: el.dataset.name,
          title: el.getAttribute('title'),
          moji: el.textContent,
        }),
      },
      {
        tag: 'img.emoji',
        getAttrs: (el) => {
          const name = el.getAttribute('title').replace(/^:|:$/g, '');

          return {
            name,
            title: name,
            moji: name,
          };
        },
      },
    ],
    toDOM: (node) => [
      'gl-emoji',
      { 'data-name': node.attrs.name, title: node.attrs.title },
      node.attrs.moji,
    ],
  },
  toMarkdown(state, node) {
    state.write(`:${node.attrs.name}:`);
  },
});
