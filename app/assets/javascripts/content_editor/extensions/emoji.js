import { Node, InputRule } from '@tiptap/core';
import { initEmojiMap, getEmojiMap } from '~/emoji';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

export default Node.create({
  name: 'emoji',

  inline: true,

  group: 'inline',

  draggable: true,

  addAttributes() {
    return {
      moji: { default: null },
      name: { default: null },
      title: { default: null },
      unicodeVersion: { default: '6.0' },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'gl-emoji',
        getAttrs: (el) => ({
          name: el.dataset.name,
          title: el.getAttribute('title'),
          moji: el.textContent,
          unicodeVersion: el.dataset.unicodeVersion || '6.0',
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
            unicodeVersion: 'custom',
          };
        },
        priority: PARSE_HTML_PRIORITY_HIGHEST,
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
