import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { initEmojiMap, EMOJI_VERSION } from '~/emoji';

export const emojiFixtureMap = {
  atom: {
    moji: '⚛',
    description: 'atom symbol',
    unicodeVersion: '4.1',
    aliases: ['atom_symbol'],
  },
  bomb: {
    moji: '💣',
    unicodeVersion: '6.0',
    description: 'bomb',
  },
  construction_worker_tone5: {
    moji: '👷🏿',
    unicodeVersion: '8.0',
    description: 'construction worker tone 5',
  },
  five: {
    moji: '5️⃣',
    unicodeVersion: '3.0',
    description: 'keycap digit five',
  },
  grey_question: {
    moji: '❔',
    unicodeVersion: '6.0',
    description: 'white question mark ornament',
  },

  // used for regression tests
  // black_heart MUST come before heart
  // custard MUST come before star
  black_heart: {
    moji: '🖤',
    unicodeVersion: '1.1',
    description: 'black heart',
  },
  heart: {
    moji: '❤',
    unicodeVersion: '1.1',
    description: 'heavy black heart',
  },
  custard: {
    moji: '🍮',
    unicodeVersion: '6.0',
    description: 'custard',
  },
  star: {
    moji: '⭐',
    unicodeVersion: '5.1',
    description: 'white medium star',
  },
};

Object.keys(emojiFixtureMap).forEach(k => {
  emojiFixtureMap[k].name = k;
  if (!emojiFixtureMap[k].aliases) {
    emojiFixtureMap[k].aliases = [];
  }
});

export async function initEmojiMock() {
  const emojiData = Object.fromEntries(
    Object.values(emojiFixtureMap).map(m => {
      const { name: n, moji: e, unicodeVersion: u, category: c, description: d } = m;
      return [n, { c, e, d, u }];
    }),
  );

  const mock = new MockAdapter(axios);
  mock.onGet(`/-/emojis/${EMOJI_VERSION}/emojis.json`).reply(200, JSON.stringify(emojiData));

  await initEmojiMap();

  return mock;
}

export function describeEmojiFields(label, tests) {
  describe.each`
    field            | accessor
    ${'name'}        | ${e => e.name}
    ${'alias'}       | ${e => e.aliases[0]}
    ${'description'} | ${e => e.description}
  `(label, tests);
}
