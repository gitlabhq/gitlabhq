import { initEmojiMap, EMOJI_VERSION } from '~/emoji';
import { CACHE_KEY } from '~/emoji/constants';

export const validEmoji = {
  atom: {
    moji: '⚛',
    description: 'atom symbol',
    unicodeVersion: '4.1',
    aliases: ['atom_symbol'],
  },
  fast_reverse_button: {
    moji: '⏪',
    description: 'fast reverse button',
    unicodeVersion: '4.1',
    aliases: ['rewind'],
  },
  bomb: {
    moji: '💣',
    unicodeVersion: '6.0',
    description: 'bomb',
  },
  construction_worker_tone5: {
    moji: '👷🏿',
    unicodeVersion: '8.0',
    description: 'construction worker: dark skin tone',
  },
  five: {
    moji: '5️⃣',
    unicodeVersion: '3.0',
    description: 'keycap: 5',
  },
  grey_question: {
    moji: '❔',
    unicodeVersion: '6.0',
    description: 'white question mark',
  },
  black_heart: {
    moji: '🖤',
    unicodeVersion: '1.1',
    description: 'black heart',
  },
  heart: {
    moji: '❤',
    unicodeVersion: '1.1',
    description: 'red heart',
  },
  custard: {
    moji: '🍮',
    unicodeVersion: '6.0',
    description: 'custard',
  },
  star: {
    moji: '⭐',
    unicodeVersion: '5.1',
    description: 'star',
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
    description: 'thumbs up',
  },
  thumbsdown: {
    moji: '👎',
    description: 'thumbs down',
    unicodeVersion: '6.0',
  },
  expressionless: {
    moji: '😑',
    description: 'expressionless face',
    unicodeVersion: '6.1',
  },
  spy: {
    moji: '🕵️',
    description: 'detective',
    unicodeVersion: '7.0',
  },
  metal: {
    moji: '🤘',
    description: 'sign of the horns',
    unicodeVersion: '8.0',
  },
  rofl: {
    moji: '🤣',
    description: 'rolling on the floor laughing',
    unicodeVersion: '9.0',
  },
  face_vomiting: {
    moji: '🤮',
    description: 'face vomiting',
    unicodeVersion: '10.0',
  },
  man_superhero: {
    moji: '🦸‍♂️',
    description: 'man superhero',
    unicodeVersion: '11.0',
  },
  person_standing: {
    moji: '🧍',
    description: 'person standing',
    unicodeVersion: '12.0',
  },
  person_red_hair: {
    moji: '🧑‍🦰',
    description: 'person: red hair',
    unicodeVersion: '12.1',
  },
  people_hugging: {
    moji: '🫂',
    description: 'people hugging',
    unicodeVersion: '13.0',
  },
  face_with_spiral_eyes: {
    moji: '😵‍💫',
    description: 'face with spiral eyes',
    unicodeVersion: '13.1',
  },
  coral: {
    moji: '🪸',
    description: 'coral',
    unicodeVersion: '14.0',
  },
  jellyfish: {
    moji: '🪼',
    description: 'jellyfish',
    unicodeVersion: '15.0',
  },
  lime: {
    moji: '🍋‍🟩',
    description: 'lime',
    unicodeVersion: '15.1',
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
  acc.push({ n: k, e, u, c, d });

  return acc;
}, []);

export function clearEmojiMock() {
  localStorage.clear();
  initEmojiMap.promise = null;
}

export async function initEmojiMock(data = mockEmojiData) {
  clearEmojiMock();
  localStorage.setItem(CACHE_KEY, JSON.stringify({ data, EMOJI_VERSION }));
  await initEmojiMap();
}
