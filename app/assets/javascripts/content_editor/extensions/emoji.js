import { Node, InputRule } from '@tiptap/core';
import { initEmojiMap, getEmojiMap } from '~/emoji';

export default Node.create({
  name: 'emoji',

  inline: true,

  group: 'inline',

  draggable: true,

  addAttributes() {
    return {
      moji: {
        default: null,
        parseHTML: (element) => element.textContent,
      },
      name: {
        default: null,
        parseHTML: (element) => element.dataset.name,
      },
      title: {
        default: null,
      },
      unicodeVersion: {
        default: '6.0',
        parseHTML: (element) => element.dataset.unicodeVersion,
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'gl-emoji',
      },
    ];
  },

  renderHTML({ node }) {
    return [
      'gl-emoji',
      {
        'data-name': node.attrs.name,
        title: node.attrs.title,
        'data-unicode-version': node.attrs.unicodeVersion,
      },
      node.attrs.moji || '',
    ];
  },

  addInputRules() {
    const emojiInputRegex = /(?:^|\s)(:(\w+):)$/;

    return [
      new InputRule({
        find: emojiInputRegex,
        handler: ({ state, range: { from, to }, match }) => {
          const [, , name] = match;
          const emojis = getEmojiMap();
          const emoji = emojis[name];
          const { tr } = state;

          if (emoji) {
            tr.replaceWith(from, to, [
              state.schema.text(' '),
              this.type.create({ name, moji: emoji.e, unicodeVersion: emoji.u, title: emoji.d }),
            ]);

            return tr;
          }

          return null;
        },
      }),
    ];
  },

  onCreate() {
    initEmojiMap();
  },
});
