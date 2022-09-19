import {
  emojiFixtureMap,
  mockEmojiData,
  initEmojiMock,
  validEmoji,
  invalidEmoji,
  clearEmojiMock,
} from 'helpers/emoji';
import { trimText } from 'helpers/text_helper';
import {
  glEmojiTag,
  searchEmoji,
  getEmojiInfo,
  sortEmoji,
  initEmojiMap,
  getAllEmoji,
} from '~/emoji';

import isEmojiUnicodeSupported, {
  isFlagEmoji,
  isRainbowFlagEmoji,
  isKeycapEmoji,
  isSkinToneComboEmoji,
  isHorceRacingSkinToneComboEmoji,
  isPersonZwjEmoji,
} from '~/emoji/support/is_emoji_unicode_supported';
import { NEUTRAL_INTENT_MULTIPLIER } from '~/emoji/constants';

const emptySupportMap = {
  personZwj: false,
  horseRacing: false,
  flag: false,
  skinToneModifier: false,
  '9.0': false,
  '8.0': false,
  '7.0': false,
  6.1: false,
  '6.0': false,
  5.2: false,
  5.1: false,
  4.1: false,
  '4.0': false,
  3.2: false,
  '3.0': false,
  1.1: false,
};

describe('emoji', () => {
  beforeEach(async () => {
    await initEmojiMock();
  });

  afterEach(() => {
    clearEmojiMock();
  });

  describe('initEmojiMap', () => {
    it('should contain valid emoji', async () => {
      await initEmojiMap();

      const allEmoji = Object.keys(getAllEmoji());
      Object.keys(validEmoji).forEach((key) => {
        expect(allEmoji.includes(key)).toBe(true);
      });
    });

    it('should not contain invalid emoji', async () => {
      await initEmojiMap();

      const allEmoji = Object.keys(getAllEmoji());
      Object.keys(invalidEmoji).forEach((key) => {
        expect(allEmoji.includes(key)).toBe(false);
      });
    });

    it('fixes broken pride emoji', async () => {
      clearEmojiMock();
      await initEmojiMock({
        gay_pride_flag: {
          c: 'flags',
          // Without a zero-width joiner
          e: '🏳🌈',
          name: 'gay_pride_flag',
          u: '6.0',
        },
      });

      expect(getAllEmoji()).toEqual({
        gay_pride_flag: {
          c: 'flags',
          // With a zero-width joiner
          e: '🏳️‍🌈',
          name: 'gay_pride_flag',
          u: '6.0',
        },
      });
    });
  });

  describe('glEmojiTag', () => {
    it('bomb emoji', () => {
      const emojiKey = 'bomb';
      const markup = glEmojiTag(emojiKey);

      expect(trimText(markup)).toMatchInlineSnapshot(
        `"<gl-emoji data-name=\\"bomb\\"></gl-emoji>"`,
      );
    });

    it('bomb emoji with sprite fallback readiness', () => {
      const emojiKey = 'bomb';
      const markup = glEmojiTag(emojiKey, {
        sprite: true,
      });
      expect(trimText(markup)).toMatchInlineSnapshot(
        `"<gl-emoji data-fallback-sprite-class=\\"emoji-bomb\\" data-name=\\"bomb\\"></gl-emoji>"`,
      );
    });
  });

  describe('isFlagEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isFlagEmoji('')).toBe(false);
    });

    it('should detect flag_ac', () => {
      expect(isFlagEmoji('🇦🇨')).toBe(true);
    });

    it('should detect flag_us', () => {
      expect(isFlagEmoji('🇺🇸')).toBe(true);
    });

    it('should detect flag_zw', () => {
      expect(isFlagEmoji('🇿🇼')).toBe(true);
    });

    it('should not detect flags', () => {
      expect(isFlagEmoji('🎏')).toBe(false);
    });

    it('should not detect triangular_flag_on_post', () => {
      expect(isFlagEmoji('🚩')).toBe(false);
    });

    it('should not detect single letter', () => {
      expect(isFlagEmoji('🇦')).toBe(false);
    });

    it('should not detect >2 letters', () => {
      expect(isFlagEmoji('🇦🇧🇨')).toBe(false);
    });
  });

  describe('isRainbowFlagEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isRainbowFlagEmoji('')).toBe(false);
    });

    it('should detect rainbow_flag', () => {
      expect(isRainbowFlagEmoji('🏳🌈')).toBe(true);
    });

    it("should not detect flag_white on its' own", () => {
      expect(isRainbowFlagEmoji('🏳')).toBe(false);
    });

    it("should not detect rainbow on its' own", () => {
      expect(isRainbowFlagEmoji('🌈')).toBe(false);
    });

    it('should not detect flag_white with something else', () => {
      expect(isRainbowFlagEmoji('🏳🔵')).toBe(false);
    });
  });

  describe('isKeycapEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isKeycapEmoji('')).toBe(false);
    });

    it('should detect one(keycap)', () => {
      expect(isKeycapEmoji('1️⃣')).toBe(true);
    });

    it('should detect nine(keycap)', () => {
      expect(isKeycapEmoji('9️⃣')).toBe(true);
    });

    it('should not detect ten(keycap)', () => {
      expect(isKeycapEmoji('🔟')).toBe(false);
    });

    it('should not detect hash(keycap)', () => {
      expect(isKeycapEmoji('#⃣')).toBe(false);
    });
  });

  describe('isSkinToneComboEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isSkinToneComboEmoji('')).toBe(false);
    });

    it('should detect hand_splayed_tone5', () => {
      expect(isSkinToneComboEmoji('🖐🏿')).toBe(true);
    });

    it('should not detect hand_splayed', () => {
      expect(isSkinToneComboEmoji('🖐')).toBe(false);
    });

    it('should detect lifter_tone1', () => {
      expect(isSkinToneComboEmoji('🏋🏻')).toBe(true);
    });

    it('should not detect lifter', () => {
      expect(isSkinToneComboEmoji('🏋')).toBe(false);
    });

    it('should detect rowboat_tone4', () => {
      expect(isSkinToneComboEmoji('🚣🏾')).toBe(true);
    });

    it('should not detect rowboat', () => {
      expect(isSkinToneComboEmoji('🚣')).toBe(false);
    });

    it('should not detect individual tone emoji', () => {
      expect(isSkinToneComboEmoji('🏻')).toBe(false);
    });
  });

  describe('isHorceRacingSkinToneComboEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isHorceRacingSkinToneComboEmoji('')).toBeUndefined();
    });

    it('should detect horse_racing_tone2', () => {
      expect(isHorceRacingSkinToneComboEmoji('🏇🏼')).toBe(true);
    });

    it('should not detect horse_racing', () => {
      expect(isHorceRacingSkinToneComboEmoji('🏇')).toBe(false);
    });
  });

  describe('isPersonZwjEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isPersonZwjEmoji('')).toBe(false);
    });

    it('should detect couple_mm', () => {
      expect(isPersonZwjEmoji('👨‍❤️‍👨')).toBe(true);
    });

    it('should not detect couple_with_heart', () => {
      expect(isPersonZwjEmoji('💑')).toBe(false);
    });

    it('should not detect couplekiss', () => {
      expect(isPersonZwjEmoji('💏')).toBe(false);
    });

    it('should detect family_mmb', () => {
      expect(isPersonZwjEmoji('👨‍👨‍👦')).toBe(true);
    });

    it('should detect family_mwgb', () => {
      expect(isPersonZwjEmoji('👨‍👩‍👧‍👦')).toBe(true);
    });

    it('should not detect family', () => {
      expect(isPersonZwjEmoji('👪')).toBe(false);
    });

    it('should detect kiss_ww', () => {
      expect(isPersonZwjEmoji('👩‍❤️‍💋‍👩')).toBe(true);
    });

    it('should not detect girl', () => {
      expect(isPersonZwjEmoji('👧')).toBe(false);
    });

    it('should not detect girl_tone5', () => {
      expect(isPersonZwjEmoji('👧🏿')).toBe(false);
    });

    it('should not detect man', () => {
      expect(isPersonZwjEmoji('👨')).toBe(false);
    });

    it('should not detect woman', () => {
      expect(isPersonZwjEmoji('👩')).toBe(false);
    });
  });

  describe('isEmojiUnicodeSupported', () => {
    it('should gracefully handle empty string with unicode support', () => {
      const isSupported = isEmojiUnicodeSupported({ '1.0': true }, '', '1.0');

      expect(isSupported).toBe(true);
    });

    it('should gracefully handle empty string without unicode support', () => {
      const isSupported = isEmojiUnicodeSupported({}, '', '1.0');

      expect(isSupported).toBeUndefined();
    });

    it('bomb(6.0) with 6.0 support', () => {
      const emojiKey = 'bomb';
      const unicodeSupportMap = { ...emptySupportMap, '6.0': true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
    });

    it('bomb(6.0) without 6.0 support', () => {
      const emojiKey = 'bomb';
      const unicodeSupportMap = emptySupportMap;
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(false);
    });

    it('bomb(6.0) without 6.0 but with 9.0 support', () => {
      const emojiKey = 'bomb';
      const unicodeSupportMap = { ...emptySupportMap, '9.0': true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(false);
    });

    it('construction_worker_tone5(8.0) without skin tone modifier support', () => {
      const emojiKey = 'construction_worker_tone5';
      const unicodeSupportMap = {
        ...emptySupportMap,
        skinToneModifier: false,
        '9.0': true,
        '8.0': true,
        '7.0': true,
        6.1: true,
        '6.0': true,
        5.2: true,
        5.1: true,
        4.1: true,
        '4.0': true,
        3.2: true,
        '3.0': true,
        1.1: true,
      };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(false);
    });

    it('use native keycap on >=57 chrome', () => {
      const emojiKey = 'five';
      const unicodeSupportMap = {
        ...emptySupportMap,
        '3.0': true,
        meta: {
          isChrome: true,
          chromeVersion: 57,
        },
      };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
    });

    it('fallback keycap on <57 chrome', () => {
      const emojiKey = 'five';
      const unicodeSupportMap = {
        ...emptySupportMap,
        '3.0': true,
        meta: {
          isChrome: true,
          chromeVersion: 50,
        },
      };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(false);
    });
  });

  describe('getEmojiInfo', () => {
    it.each(['atom', 'five', 'black_heart'])("should return a correct emoji for '%s'", (name) => {
      expect(getEmojiInfo(name)).toEqual(mockEmojiData[name]);
    });

    it('should return fallback emoji by default', () => {
      expect(getEmojiInfo('atjs')).toEqual(mockEmojiData.grey_question);
    });

    it('should return null when fallback is false', () => {
      expect(getEmojiInfo('atjs', false)).toBe(null);
    });

    describe('when query is undefined', () => {
      it('should return fallback emoji by default', () => {
        expect(getEmojiInfo()).toEqual(mockEmojiData.grey_question);
      });

      it('should return null when fallback is false', () => {
        expect(getEmojiInfo(undefined, false)).toBe(null);
      });
    });
  });

  describe('searchEmoji', () => {
    it.each([undefined, null, ''])("should return all emoji when the input is '%s'", (input) => {
      const search = searchEmoji(input);

      const expected = Object.keys(validEmoji)
        .map((name) => {
          let score = NEUTRAL_INTENT_MULTIPLIER;

          // Positive intent value retrieved from ~/emoji/intents.json
          if (name === 'thumbsup') {
            score = 0.5;
          }

          // Negative intent value retrieved from ~/emoji/intents.json
          if (name === 'thumbsdown') {
            score = 1.5;
          }

          return {
            emoji: mockEmojiData[name],
            field: 'd',
            fieldValue: mockEmojiData[name].d,
            score,
          };
        })
        .sort(sortEmoji);

      expect(search).toEqual(expected);
    });

    it.each([
      [
        'searching by unicode value',
        '⚛',
        [
          {
            name: 'atom',
            field: 'e',
            fieldValue: 'atom',
            score: NEUTRAL_INTENT_MULTIPLIER,
          },
        ],
      ],
      [
        'searching by partial alias',
        '_symbol',
        [
          {
            name: 'atom',
            field: 'alias',
            fieldValue: 'atom_symbol',
            score: 16,
          },
        ],
      ],
      [
        'searching by full alias',
        'atom_symbol',
        [
          {
            name: 'atom',
            field: 'alias',
            fieldValue: 'atom_symbol',
            score: NEUTRAL_INTENT_MULTIPLIER,
          },
        ],
      ],
    ])('should return a correct result when %s', (_, query, searchResult) => {
      const expected = searchResult.map((item) => {
        const { field, score, fieldValue, name } = item;

        return {
          emoji: mockEmojiData[name],
          field,
          fieldValue,
          score,
        };
      });

      expect(searchEmoji(query)).toEqual(expected);
    });

    it.each([
      ['searching with a non-existing emoji name', 'asdf', []],
      [
        'searching by full name',
        'atom',
        [
          {
            name: 'atom',
            field: 'd',
            score: NEUTRAL_INTENT_MULTIPLIER,
          },
        ],
      ],

      [
        'searching by full description',
        'atom symbol',
        [
          {
            name: 'atom',
            field: 'd',
            score: NEUTRAL_INTENT_MULTIPLIER,
          },
        ],
      ],

      [
        'searching by partial name',
        'question',
        [
          {
            name: 'grey_question',
            field: 'name',
            score: 32,
          },
        ],
      ],
      [
        'searching by partial description',
        'ment',
        [
          {
            name: 'grey_question',
            field: 'd',
            score: 16777216,
          },
        ],
      ],
      [
        'searching with query "heart"',
        'heart',
        [
          {
            name: 'heart',
            field: 'name',
            score: NEUTRAL_INTENT_MULTIPLIER,
          },
          {
            name: 'black_heart',
            field: 'd',
            score: 64,
          },
        ],
      ],
      [
        'searching with query "HEART"',
        'HEART',
        [
          {
            name: 'heart',
            field: 'name',
            score: NEUTRAL_INTENT_MULTIPLIER,
          },
          {
            name: 'black_heart',
            field: 'd',
            score: 64,
          },
        ],
      ],
      [
        'searching with query "star"',
        'star',
        [
          {
            name: 'star',
            field: 'name',
            score: NEUTRAL_INTENT_MULTIPLIER,
          },
          {
            name: 'custard',
            field: 'd',
            score: 4,
          },
        ],
      ],
      [
        'searching for emoji with intentions assigned',
        'thumbs',
        [
          {
            name: 'thumbsup',
            field: 'd',
            score: 0.5,
          },
          {
            name: 'thumbsdown',
            field: 'd',
            score: 1.5,
          },
        ],
      ],
    ])('should return a correct result when %s', (_, query, searchResult) => {
      const expected = searchResult.map((item) => {
        const { field, score, name } = item;

        return {
          emoji: mockEmojiData[name],
          field,
          fieldValue: mockEmojiData[name][field],
          score,
        };
      });

      expect(searchEmoji(query)).toEqual(expected);
    });
  });

  describe('sortEmoji', () => {
    const testCases = [
      [
        'should correctly sort by score',
        [
          { score: 10, fieldValue: '', emoji: { name: 'a' } },
          { score: 5, fieldValue: '', emoji: { name: 'b' } },
          { score: 1, fieldValue: '', emoji: { name: 'c' } },
        ],
        [
          { score: 1, fieldValue: '', emoji: { name: 'c' } },
          { score: 5, fieldValue: '', emoji: { name: 'b' } },
          { score: 10, fieldValue: '', emoji: { name: 'a' } },
        ],
      ],
      [
        'should correctly sort by fieldValue',
        [
          { score: 1, fieldValue: 'y', emoji: { name: 'b' } },
          { score: 1, fieldValue: 'x', emoji: { name: 'a' } },
          { score: 1, fieldValue: 'z', emoji: { name: 'c' } },
        ],
        [
          { score: 1, fieldValue: 'x', emoji: { name: 'a' } },
          { score: 1, fieldValue: 'y', emoji: { name: 'b' } },
          { score: 1, fieldValue: 'z', emoji: { name: 'c' } },
        ],
      ],
      [
        'should correctly sort by score and then by fieldValue (in order)',
        [
          { score: 5, fieldValue: 'y', emoji: { name: 'c' } },
          { score: 1, fieldValue: 'z', emoji: { name: 'a' } },
          { score: 5, fieldValue: 'x', emoji: { name: 'b' } },
        ],
        [
          { score: 1, fieldValue: 'z', emoji: { name: 'a' } },
          { score: 5, fieldValue: 'x', emoji: { name: 'b' } },
          { score: 5, fieldValue: 'y', emoji: { name: 'c' } },
        ],
      ],
    ];

    it.each(testCases)('%s', (_, scoredItems, expected) => {
      expect(scoredItems.sort(sortEmoji)).toEqual(expected);
    });
  });
});
