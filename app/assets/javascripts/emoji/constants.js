export const FREQUENTLY_USED_KEY = 'frequently_used';
export const FREQUENTLY_USED_EMOJIS_STORAGE_KEY = 'frequently_used_emojis';

export const EMOJI_THUMBS_UP = 'thumbsup';
export const EMOJI_THUMBS_DOWN = 'thumbsdown';

/* eslint-disable @gitlab/require-i18n-strings */
export const CATEGORY_NAMES = [
  FREQUENTLY_USED_KEY,
  'custom',
  'Smileys & Emotion',
  'People & Body',
  'Animals & Nature',
  'Food & Drink',
  'Travel & Places',
  'Activities',
  'Objects',
  'Symbols',
  'Flags',
];
export const CATEGORY_ICON_MAP = {
  [FREQUENTLY_USED_KEY]: 'history',
  custom: 'tanuki',
  'Smileys & Emotion': 'smiley',
  'People & Body': 'users',
  'Animals & Nature': 'nature',
  'Food & Drink': 'food',
  'Travel & Places': 'car',
  Activities: 'dumbbell',
  Objects: 'object',
  Symbols: 'trigger-source',
  Flags: 'flag',
};
/* eslint-enable @gitlab/require-i18n-strings */

export const EMOJIS_PER_ROW = 9;
export const EMOJI_ROW_HEIGHT = 36;
export const CATEGORY_ROW_HEIGHT = 37;

export const CACHE_VERSION_KEY = 'gl-emoji-map-version';
export const CACHE_KEY = 'gl-emoji-map';

export const NEUTRAL_INTENT_MULTIPLIER = 1;
