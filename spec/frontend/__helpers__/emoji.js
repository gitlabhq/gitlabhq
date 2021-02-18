import MockAdapter from 'axios-mock-adapter';
import { initEmojiMap, EMOJI_VERSION } from '~/emoji';
import axios from '~/lib/utils/axios_utils';

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

export const mockEmojiData = Object.keys(emojiFixtureMap).reduce((acc, k) => {
  const { moji: e, unicodeVersion: u, category: c, description: d } = emojiFixtureMap[k];
  acc[k] = { name: k, e, u, c, d };

  return acc;
}, {});

export async function initEmojiMock(mockData = mockEmojiData) {
  const mock = new MockAdapter(axios);
  mock.onGet(`/-/emojis/${EMOJI_VERSION}/emojis.json`).reply(200, JSON.stringify(mockData));

  await initEmojiMap();

  return mock;
}
