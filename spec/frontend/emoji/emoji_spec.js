import { trimText } from 'helpers/text_helper';
import { emojiFixtureMap, initEmojiMock, describeEmojiFields } from 'helpers/emoji';
import { glEmojiTag, searchEmoji, getEmoji } from '~/emoji';
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

describe('gl_emoji', () => {
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
      const markup = glEmojiTag(emojiFixtureMap[emojiKey].name);

      expect(trimText(markup)).toMatchInlineSnapshot(
        `"<gl-emoji data-name=\\"bomb\\"></gl-emoji>"`,
      );
    });

    it('bomb emoji with sprite fallback readiness', () => {
      const emojiKey = 'bomb';
      const markup = glEmojiTag(emojiFixtureMap[emojiKey].name, {
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

  describe('getEmoji', () => {
    const { grey_question } = emojiFixtureMap;

    describe('when query is undefined', () => {
      it('should return null by default', () => {
        expect(getEmoji()).toBe(null);
      });

      it('should return fallback emoji when fallback is true', () => {
        expect(getEmoji(undefined, true).name).toEqual(grey_question.name);
      });
    });
  });

  describe('searchEmoji', () => {
    const { atom, grey_question } = emojiFixtureMap;
    const search = (query, opts) => searchEmoji(query, opts).map(({ name }) => name);
    const mangle = str => str.slice(0, 1) + str.slice(-1);
    const partial = str => str.slice(0, 2);

    describe('with default options', () => {
      const subject = query => search(query);

      describeEmojiFields('with $field', ({ accessor }) => {
        it(`should match by lower case: ${accessor(atom)}`, () => {
          expect(subject(accessor(atom))).toContain(atom.name);
        });

        it(`should match by upper case: ${accessor(atom).toUpperCase()}`, () => {
          expect(subject(accessor(atom).toUpperCase())).toContain(atom.name);
        });

        it(`should not match by partial: ${mangle(accessor(atom))}`, () => {
          expect(subject(mangle(accessor(atom)))).not.toContain(atom.name);
        });
      });

      it(`should match by unicode value: ${atom.moji}`, () => {
        expect(subject(atom.moji)).toContain(atom.name);
      });

      it('should not return a fallback value', () => {
        expect(subject('foo bar baz')).toHaveLength(0);
      });

      it('should not return a fallback value when query is falsey', () => {
        expect(subject()).toHaveLength(0);
      });
    });

    describe('with fuzzy match', () => {
      const subject = query => search(query, { match: 'fuzzy' });

      describeEmojiFields('with $field', ({ accessor }) => {
        it(`should match by lower case: ${accessor(atom)}`, () => {
          expect(subject(accessor(atom))).toContain(atom.name);
        });

        it(`should match by upper case: ${accessor(atom).toUpperCase()}`, () => {
          expect(subject(accessor(atom).toUpperCase())).toContain(atom.name);
        });

        it(`should match by partial: ${mangle(accessor(atom))}`, () => {
          expect(subject(mangle(accessor(atom)))).toContain(atom.name);
        });
      });
    });

    describe('with contains match', () => {
      const subject = query => search(query, { match: 'contains' });

      describeEmojiFields('with $field', ({ accessor }) => {
        it(`should match by lower case: ${accessor(atom)}`, () => {
          expect(subject(accessor(atom))).toContain(atom.name);
        });

        it(`should match by upper case: ${accessor(atom).toUpperCase()}`, () => {
          expect(subject(accessor(atom).toUpperCase())).toContain(atom.name);
        });

        it(`should match by partial: ${partial(accessor(atom))}`, () => {
          expect(subject(partial(accessor(atom)))).toContain(atom.name);
        });

        it(`should not match by mangled: ${mangle(accessor(atom))}`, () => {
          expect(subject(mangle(accessor(atom)))).not.toContain(atom.name);
        });
      });
    });

    describe('with fallback', () => {
      const subject = query => search(query, { fallback: true });

      it.each`
        query
        ${'foo bar baz'} | ${undefined}
      `('should return a fallback value when given $query', ({ query }) => {
        expect(subject(query)).toContain(grey_question.name);
      });
    });

    describe('with name and alias fields', () => {
      const subject = query => search(query, { fields: ['name', 'alias'] });

      it(`should match by name: ${atom.name}`, () => {
        expect(subject(atom.name)).toContain(atom.name);
      });

      it(`should match by alias: ${atom.aliases[0]}`, () => {
        expect(subject(atom.aliases[0])).toContain(atom.name);
      });

      it(`should not match by description: ${atom.description}`, () => {
        expect(subject(atom.description)).not.toContain(atom.name);
      });

      it(`should not match by unicode value: ${atom.moji}`, () => {
        expect(subject(atom.moji)).not.toContain(atom.name);
      });
    });
  });
});
