import { emojiFixtureMap, mockEmojiData, initEmojiMock } from 'helpers/emoji';
import { trimText } from 'helpers/text_helper';
import { glEmojiTag, searchEmoji, getEmojiInfo, sortEmoji } from '~/emoji';
import isEmojiUnicodeSupported, {
  isFlagEmoji,
  isRainbowFlagEmoji,
  isKeycapEmoji,
  isSkinToneComboEmoji,
  isHorceRacingSkinToneComboEmoji,
  isPersonZwjEmoji,
} from '~/emoji/support/is_emoji_unicode_supported';

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
  let mock;

  beforeEach(async () => {
    mock = await initEmojiMock();
  });

  afterEach(() => {
    mock.restore();
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
      expect(isFlagEmoji('')).toBeFalsy();
    });

    it('should detect flag_ac', () => {
      expect(isFlagEmoji('🇦🇨')).toBeTruthy();
    });

    it('should detect flag_us', () => {
      expect(isFlagEmoji('🇺🇸')).toBeTruthy();
    });

    it('should detect flag_zw', () => {
      expect(isFlagEmoji('🇿🇼')).toBeTruthy();
    });

    it('should not detect flags', () => {
      expect(isFlagEmoji('🎏')).toBeFalsy();
    });

    it('should not detect triangular_flag_on_post', () => {
      expect(isFlagEmoji('🚩')).toBeFalsy();
    });

    it('should not detect single letter', () => {
      expect(isFlagEmoji('🇦')).toBeFalsy();
    });

    it('should not detect >2 letters', () => {
      expect(isFlagEmoji('🇦🇧🇨')).toBeFalsy();
    });
  });

  describe('isRainbowFlagEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isRainbowFlagEmoji('')).toBeFalsy();
    });

    it('should detect rainbow_flag', () => {
      expect(isRainbowFlagEmoji('🏳🌈')).toBeTruthy();
    });

    it("should not detect flag_white on its' own", () => {
      expect(isRainbowFlagEmoji('🏳')).toBeFalsy();
    });

    it("should not detect rainbow on its' own", () => {
      expect(isRainbowFlagEmoji('🌈')).toBeFalsy();
    });

    it('should not detect flag_white with something else', () => {
      expect(isRainbowFlagEmoji('🏳🔵')).toBeFalsy();
    });
  });

  describe('isKeycapEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isKeycapEmoji('')).toBeFalsy();
    });

    it('should detect one(keycap)', () => {
      expect(isKeycapEmoji('1️⃣')).toBeTruthy();
    });

    it('should detect nine(keycap)', () => {
      expect(isKeycapEmoji('9️⃣')).toBeTruthy();
    });

    it('should not detect ten(keycap)', () => {
      expect(isKeycapEmoji('🔟')).toBeFalsy();
    });

    it('should not detect hash(keycap)', () => {
      expect(isKeycapEmoji('#⃣')).toBeFalsy();
    });
  });

  describe('isSkinToneComboEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isSkinToneComboEmoji('')).toBeFalsy();
    });

    it('should detect hand_splayed_tone5', () => {
      expect(isSkinToneComboEmoji('🖐🏿')).toBeTruthy();
    });

    it('should not detect hand_splayed', () => {
      expect(isSkinToneComboEmoji('🖐')).toBeFalsy();
    });

    it('should detect lifter_tone1', () => {
      expect(isSkinToneComboEmoji('🏋🏻')).toBeTruthy();
    });

    it('should not detect lifter', () => {
      expect(isSkinToneComboEmoji('🏋')).toBeFalsy();
    });

    it('should detect rowboat_tone4', () => {
      expect(isSkinToneComboEmoji('🚣🏾')).toBeTruthy();
    });

    it('should not detect rowboat', () => {
      expect(isSkinToneComboEmoji('🚣')).toBeFalsy();
    });

    it('should not detect individual tone emoji', () => {
      expect(isSkinToneComboEmoji('🏻')).toBeFalsy();
    });
  });

  describe('isHorceRacingSkinToneComboEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isHorceRacingSkinToneComboEmoji('')).toBeFalsy();
    });

    it('should detect horse_racing_tone2', () => {
      expect(isHorceRacingSkinToneComboEmoji('🏇🏼')).toBeTruthy();
    });

    it('should not detect horse_racing', () => {
      expect(isHorceRacingSkinToneComboEmoji('🏇')).toBeFalsy();
    });
  });

  describe('isPersonZwjEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isPersonZwjEmoji('')).toBeFalsy();
    });

    it('should detect couple_mm', () => {
      expect(isPersonZwjEmoji('👨‍❤️‍👨')).toBeTruthy();
    });

    it('should not detect couple_with_heart', () => {
      expect(isPersonZwjEmoji('💑')).toBeFalsy();
    });

    it('should not detect couplekiss', () => {
      expect(isPersonZwjEmoji('💏')).toBeFalsy();
    });

    it('should detect family_mmb', () => {
      expect(isPersonZwjEmoji('👨‍👨‍👦')).toBeTruthy();
    });

    it('should detect family_mwgb', () => {
      expect(isPersonZwjEmoji('👨‍👩‍👧‍👦')).toBeTruthy();
    });

    it('should not detect family', () => {
      expect(isPersonZwjEmoji('👪')).toBeFalsy();
    });

    it('should detect kiss_ww', () => {
      expect(isPersonZwjEmoji('👩‍❤️‍💋‍👩')).toBeTruthy();
    });

    it('should not detect girl', () => {
      expect(isPersonZwjEmoji('👧')).toBeFalsy();
    });

    it('should not detect girl_tone5', () => {
      expect(isPersonZwjEmoji('👧🏿')).toBeFalsy();
    });

    it('should not detect man', () => {
      expect(isPersonZwjEmoji('👨')).toBeFalsy();
    });

    it('should not detect woman', () => {
      expect(isPersonZwjEmoji('👩')).toBeFalsy();
    });
  });

  describe('isEmojiUnicodeSupported', () => {
    it('should gracefully handle empty string with unicode support', () => {
      const isSupported = isEmojiUnicodeSupported({ '1.0': true }, '', '1.0');

      expect(isSupported).toBeTruthy();
    });

    it('should gracefully handle empty string without unicode support', () => {
      const isSupported = isEmojiUnicodeSupported({}, '', '1.0');

      expect(isSupported).toBeFalsy();
    });

    it('bomb(6.0) with 6.0 support', () => {
      const emojiKey = 'bomb';
      const unicodeSupportMap = { ...emptySupportMap, '6.0': true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBeTruthy();
    });

    it('bomb(6.0) without 6.0 support', () => {
      const emojiKey = 'bomb';
      const unicodeSupportMap = emptySupportMap;
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBeFalsy();
    });

    it('bomb(6.0) without 6.0 but with 9.0 support', () => {
      const emojiKey = 'bomb';
      const unicodeSupportMap = { ...emptySupportMap, '9.0': true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBeFalsy();
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

      expect(isSupported).toBeFalsy();
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

      expect(isSupported).toBeTruthy();
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

      expect(isSupported).toBeFalsy();
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
    const emojiFixture = Object.keys(mockEmojiData).reduce((acc, k) => {
      const { name, e, u, d } = mockEmojiData[k];
      acc[k] = { name, e, u, d };

      return acc;
    }, {});

    it.each([undefined, null, ''])("should return all emoji when the input is '%s'", (input) => {
      const search = searchEmoji(input);

      const expected = [
        'atom',
        'bomb',
        'construction_worker_tone5',
        'five',
        'grey_question',
        'black_heart',
        'heart',
        'custard',
        'star',
      ].map((name) => {
        return {
          emoji: emojiFixture[name],
          field: 'd',
          fieldValue: emojiFixture[name].d,
          score: 0,
        };
      });

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
            score: 0,
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
            score: 4,
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
            score: 0,
          },
        ],
      ],
    ])('should return a correct result when %s', (_, query, searchResult) => {
      const expected = searchResult.map((item) => {
        const { field, score, fieldValue, name } = item;

        return {
          emoji: emojiFixture[name],
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
            score: 0,
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
            score: 0,
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
            score: 5,
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
            score: 24,
          },
        ],
      ],
      [
        'searching with query "heart"',
        'heart',
        [
          {
            name: 'black_heart',
            field: 'd',
            score: 6,
          },
          {
            name: 'heart',
            field: 'name',
            score: 0,
          },
        ],
      ],
      [
        'searching with query "HEART"',
        'HEART',
        [
          {
            name: 'black_heart',
            field: 'd',
            score: 6,
          },
          {
            name: 'heart',
            field: 'name',
            score: 0,
          },
        ],
      ],
      [
        'searching with query "star"',
        'star',
        [
          {
            name: 'custard',
            field: 'd',
            score: 2,
          },
          {
            name: 'star',
            field: 'name',
            score: 0,
          },
        ],
      ],
    ])('should return a correct result when %s', (_, query, searchResult) => {
      const expected = searchResult.map((item) => {
        const { field, score, name } = item;

        return {
          emoji: emojiFixture[name],
          field,
          fieldValue: emojiFixture[name][field],
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
          { score: 0, fieldValue: '', emoji: { name: 'c' } },
        ],
        [
          { score: 0, fieldValue: '', emoji: { name: 'c' } },
          { score: 5, fieldValue: '', emoji: { name: 'b' } },
          { score: 10, fieldValue: '', emoji: { name: 'a' } },
        ],
      ],
      [
        'should correctly sort by fieldValue',
        [
          { score: 0, fieldValue: 'y', emoji: { name: 'b' } },
          { score: 0, fieldValue: 'x', emoji: { name: 'a' } },
          { score: 0, fieldValue: 'z', emoji: { name: 'c' } },
        ],
        [
          { score: 0, fieldValue: 'x', emoji: { name: 'a' } },
          { score: 0, fieldValue: 'y', emoji: { name: 'b' } },
          { score: 0, fieldValue: 'z', emoji: { name: 'c' } },
        ],
      ],
      [
        'should correctly sort by score and then by fieldValue (in order)',
        [
          { score: 5, fieldValue: 'y', emoji: { name: 'c' } },
          { score: 0, fieldValue: 'z', emoji: { name: 'a' } },
          { score: 5, fieldValue: 'x', emoji: { name: 'b' } },
        ],
        [
          { score: 0, fieldValue: 'z', emoji: { name: 'a' } },
          { score: 5, fieldValue: 'x', emoji: { name: 'b' } },
          { score: 5, fieldValue: 'y', emoji: { name: 'c' } },
        ],
      ],
    ];

    it.each(testCases)('%s', (_, scoredItems, expected) => {
      expect(sortEmoji(scoredItems)).toEqual(expected);
    });
  });
});
