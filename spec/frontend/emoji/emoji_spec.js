import MockAdapter from 'axios-mock-adapter';
import { trimText } from 'helpers/text_helper';
import axios from '~/lib/utils/axios_utils';
import { initEmojiMap, glEmojiTag, searchEmoji, EMOJI_VERSION } from '~/emoji';
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

const emojiFixtureMap = {
  atom: {
    name: 'atom',
    moji: '⚛',
    description: 'atom symbol',
    unicodeVersion: '4.1',
  },
  bomb: {
    name: 'bomb',
    moji: '💣',
    unicodeVersion: '6.0',
    description: 'bomb',
  },
  construction_worker_tone5: {
    name: 'construction_worker_tone5',
    moji: '👷🏿',
    unicodeVersion: '8.0',
    description: 'construction worker tone 5',
  },
  five: {
    name: 'five',
    moji: '5️⃣',
    unicodeVersion: '3.0',
    description: 'keycap digit five',
  },
  grey_question: {
    name: 'grey_question',
    moji: '❔',
    unicodeVersion: '6.0',
    description: 'white question mark ornament',
  },
};

describe('gl_emoji', () => {
  let mock;

  beforeEach(() => {
    const emojiData = Object.fromEntries(
      Object.values(emojiFixtureMap).map(m => {
        const { name: n, moji: e, unicodeVersion: u, category: c, description: d } = m;
        return [n, { c, e, d, u }];
      }),
    );

    mock = new MockAdapter(axios);
    mock.onGet(`/-/emojis/${EMOJI_VERSION}/emojis.json`).reply(200, JSON.stringify(emojiData));

    return initEmojiMap().catch(() => {});
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

  describe('searchEmoji', () => {
    const { atom, grey_question } = emojiFixtureMap;
    const contains = (e, term) =>
      expect(searchEmoji(term).map(({ name }) => name)).toContain(e.name);

    it('should match by full name', () => contains(grey_question, 'grey_question'));
    it('should match by full alias', () => contains(atom, 'atom_symbol'));
    it('should match by full description', () => contains(grey_question, 'ornament'));

    it('should match by partial name', () => contains(grey_question, 'question'));
    it('should match by partial alias', () => contains(atom, '_symbol'));
    it('should match by partial description', () => contains(grey_question, 'ment'));

    it('should fuzzy match by name', () => contains(grey_question, 'greion'));
    it('should fuzzy match by alias', () => contains(atom, 'atobol'));
    it('should fuzzy match by description', () => contains(grey_question, 'ornt'));

    it('should match by character', () => contains(grey_question, '❔'));
  });
});
