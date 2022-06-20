import { initEmojiMap, EMOJI_VERSION } from '~/emoji';
import { CACHE_VERSION_KEY, CACHE_KEY } from '~/emoji/constants';

export const validEmoji = {
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
  gay_pride_flag: {
    moji: '🏳️‍🌈',
    unicodeVersion: '7.0',
    description: 'because it contains a zero width joiner',
  },
  family_mmb: {
    moji: '👨‍👨‍👦',
    unicodeVersion: '6.0',
    description: 'because it contains multiple zero width joiners',
  },
  thumbsup: {
    moji: '👍',
    unicodeVersion: '6.0',
    description: 'thumbs up sign',
  },
  thumbsdown: {
    moji: '👎',
    description: 'thumbs down sign',
    unicodeVersion: '6.0',
  },
};

export const invalidEmoji = {
  xss: {
    moji: '<img src=x onerror=prompt(1)>',
    unicodeVersion: '5.1',
    description: 'xss',
  },
  non_moji: {
    moji: 'I am not an emoji...',
    unicodeVersion: '9.0',
    description: '...and should be filtered out',
  },
  multiple_moji: {
    moji: '🍂🏭',
    unicodeVersion: '9.0',
    description: 'Multiple separate emoji that are not joined by a zero width joiner',
  },
};

export const emojiFixtureMap = {
  ...validEmoji,
  ...invalidEmoji,
};

export const mockEmojiData = Object.keys(emojiFixtureMap).reduce((acc, k) => {
  const { moji: e, unicodeVersion: u, category: c, description: d } = emojiFixtureMap[k];
  acc[k] = { name: k, e, u, c, d };

  return acc;
}, {});

export function clearEmojiMock() {
  localStorage.clear();
  initEmojiMap.promise = null;
}

export async function initEmojiMock(mockData = mockEmojiData) {
  clearEmojiMock();
  localStorage.setItem(CACHE_VERSION_KEY, EMOJI_VERSION);
  localStorage.setItem(CACHE_KEY, JSON.stringify(mockData));
  await initEmojiMap();
}
