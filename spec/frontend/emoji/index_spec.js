import MockAdapter from 'axios-mock-adapter';
import {
  emojiFixtureMap,
  initEmojiMock,
  validEmoji,
  invalidEmoji,
  clearEmojiMock,
  mockEmojiData,
} from 'helpers/emoji';
import { trimText } from 'helpers/text_helper';
import { createMockClient } from 'helpers/mock_apollo_helper';
import {
  glEmojiTag,
  searchEmoji,
  getEmojiInfo,
  sortEmoji,
  initEmojiMap,
  getEmojiMap,
  emojiFallbackImageSrc,
  loadCustomEmojiWithNames,
  EMOJI_VERSION,
} from '~/emoji';

import isEmojiUnicodeSupported, {
  isFlagEmoji,
  isRainbowFlagEmoji,
  isKeycapEmoji,
  isSkinToneComboEmoji,
  isHorceRacingSkinToneComboEmoji,
  isPersonZwjEmoji,
} from '~/emoji/support/is_emoji_unicode_supported';
import {
  CACHE_KEY,
  CACHE_VERSION_KEY,
  EMOJI_THUMBS_UP,
  EMOJI_THUMBS_DOWN,
  NEUTRAL_INTENT_MULTIPLIER,
} from '~/emoji/constants';
import customEmojiQuery from '~/emoji/queries/custom_emoji.query.graphql';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { useLocalStorageSpy } from 'jest/__helpers__/local_storage_helper';

let mockClient;
jest.mock('~/lib/graphql', () => {
  return () => mockClient;
});

const emptySupportMap = {
  personZwj: false,
  horseRacing: false,
  flag: false,
  skinToneModifier: false,
  15.1: false,
  '15.0': false,
  '14.0': false,
  13.1: false,
  '13.0': false,
  12.1: false,
  '12.0': false,
  '11.0': false,
  '10.0': false,
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

function createMockEmojiClient(hasNextPage = false) {
  mockClient = createMockClient(
    [
      [
        customEmojiQuery,
        ({ after }) =>
          Promise.resolve({
            data: {
              group: {
                id: 1,
                customEmoji: {
                  pageInfo: {
                    hasNextPage: after ? false : hasNextPage,
                    endCursor: 'test',
                  },
                  nodes: [{ id: 1, name: `parrot${after ? `-${after}` : ''}`, url: 'parrot.gif' }],
                },
              },
            },
          }),
      ],
    ],
    {},
    {
      typePolicies: {
        Query: {
          fields: {
            group: {
              merge: true,
            },
          },
        },
      },
    },
  );

  document.body.dataset.groupFullPath = 'test-group';
}

describe('retrieval of emojis.json', () => {
  useLocalStorageSpy();

  let mock;
  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(/emojis\.json$/).reply(HTTP_STATUS_OK, mockEmojiData);
    initEmojiMap.promise = null;
  });

  afterEach(() => {
    mock.restore();
  });

  const assertCorrectLocalStorage = () => {
    expect(localStorage.length).toBe(1);
    expect(localStorage.getItem(CACHE_KEY)).toBe(
      JSON.stringify({ data: mockEmojiData, EMOJI_VERSION }),
    );
  };

  const assertEmojiBeingLoadedCorrectly = () => {
    expect(Object.keys(getEmojiMap())).toEqual(Object.keys(validEmoji));
  };

  it('should remove the old `CACHE_VERSION_KEY`', async () => {
    localStorage.setItem(CACHE_VERSION_KEY, EMOJI_VERSION);

    await initEmojiMap();

    expect(localStorage.getItem(CACHE_VERSION_KEY)).toBe(null);
  });

  describe('when the localStorage is empty', () => {
    it('should call the API and store results in localStorage', async () => {
      await initEmojiMap();

      assertEmojiBeingLoadedCorrectly();
      expect(mock.history.get.length).toBe(1);
      assertCorrectLocalStorage();
    });
  });

  describe('when the localStorage stores the correct version', () => {
    beforeEach(async () => {
      localStorage.setItem(CACHE_KEY, JSON.stringify({ data: mockEmojiData, EMOJI_VERSION }));
      localStorage.setItem.mockClear();
      await initEmojiMap();
    });

    it('should not call the API and not mutate the localStorage', () => {
      assertEmojiBeingLoadedCorrectly();
      expect(mock.history.get.length).toBe(0);
      expect(localStorage.setItem).not.toHaveBeenCalled();
      assertCorrectLocalStorage();
    });
  });

  describe('when the localStorage stores an incorrect version', () => {
    beforeEach(async () => {
      localStorage.setItem(
        CACHE_KEY,
        JSON.stringify({ data: mockEmojiData, EMOJI_VERSION: `${EMOJI_VERSION}-different` }),
      );
      localStorage.setItem.mockClear();
      await initEmojiMap();
    });

    it('should call the API and store results in localStorage', () => {
      assertEmojiBeingLoadedCorrectly();
      expect(mock.history.get.length).toBe(1);
      assertCorrectLocalStorage();
    });
  });

  describe('when the localStorage stores corrupted data', () => {
    beforeEach(async () => {
      localStorage.setItem(CACHE_KEY, "[invalid: 'INVALID_JSON");
      localStorage.setItem.mockClear();
      await initEmojiMap();
    });

    it('should call the API and store results in localStorage', () => {
      assertEmojiBeingLoadedCorrectly();
      expect(mock.history.get.length).toBe(1);
      assertCorrectLocalStorage();
    });
  });

  describe('when the localStorage stores data in a different format', () => {
    beforeEach(async () => {
      localStorage.setItem(CACHE_KEY, JSON.stringify([]));
      localStorage.setItem.mockClear();
      await initEmojiMap();
    });

    it('should call the API and store results in localStorage', () => {
      assertEmojiBeingLoadedCorrectly();
      expect(mock.history.get.length).toBe(1);
      assertCorrectLocalStorage();
    });
  });

  describe('when the localStorage is full', () => {
    beforeEach(async () => {
      const oldSetItem = localStorage.setItem;
      localStorage.setItem = jest.fn().mockImplementationOnce((key, value) => {
        if (key === CACHE_KEY) {
          throw new Error('Storage Full');
        }
        oldSetItem(key, value);
      });
      await initEmojiMap();
    });

    it('should call API but not store the results', () => {
      assertEmojiBeingLoadedCorrectly();
      expect(mock.history.get.length).toBe(1);
      expect(localStorage.length).toBe(0);
      expect(localStorage.setItem).toHaveBeenCalledTimes(1);
      expect(localStorage.setItem).toHaveBeenCalledWith(
        CACHE_KEY,
        JSON.stringify({ data: mockEmojiData, EMOJI_VERSION }),
      );
    });
  });

  describe('backwards compatibility', () => {
    // As per: https://gitlab.com/gitlab-org/gitlab/-/blob/62b66abd3bb7801e7c85b4e42a1bbd51fbb37c1b/app/assets/javascripts/emoji/index.js#L27-52
    async function prevImplementation() {
      if (
        window.localStorage.getItem(CACHE_VERSION_KEY) === EMOJI_VERSION &&
        window.localStorage.getItem(CACHE_KEY)
      ) {
        return JSON.parse(window.localStorage.getItem(CACHE_KEY));
      }

      // We load the JSON file direct from the server
      // because it can't be loaded from a CDN due to
      // cross domain problems with JSON
      const { data } = await axios.get(
        `${gon.relative_url_root || ''}/-/emojis/${EMOJI_VERSION}/emojis.json`,
      );

      try {
        window.localStorage.setItem(CACHE_VERSION_KEY, EMOJI_VERSION);
        window.localStorage.setItem(CACHE_KEY, JSON.stringify(data));
      } catch {
        // Setting data in localstorage may fail when storage quota is exceeded.
        // We should continue even when this fails.
      }

      return data;
    }

    it('Old -> New -> Old should not break', async () => {
      // The follow steps simulate a multi-version deployment. e.g.
      // Hitting a page on "regular" .com, then canary, and then "regular" again

      // Load emoji the old way to pre-populate the cache
      let res = await prevImplementation();
      expect(res).toEqual(mockEmojiData);
      expect(mock.history.get.length).toBe(1);
      localStorage.setItem.mockClear();

      // Load emoji the new way
      await initEmojiMap();
      expect(mock.history.get.length).toBe(2);
      assertEmojiBeingLoadedCorrectly();
      assertCorrectLocalStorage();
      localStorage.setItem.mockClear();

      // Load emoji the old way to pre-populate the cache
      res = await prevImplementation();
      expect(res).toEqual(mockEmojiData);
      expect(mock.history.get.length).toBe(3);
      expect(localStorage.setItem.mock.calls).toEqual([
        [CACHE_VERSION_KEY, EMOJI_VERSION],
        [CACHE_KEY, JSON.stringify(mockEmojiData)],
      ]);

      // Load emoji the old way should work again (and be taken from the cache)
      res = await prevImplementation();
      expect(res).toEqual(mockEmojiData);
      expect(mock.history.get.length).toBe(3);
    });
  });
});

describe('emoji', () => {
  beforeEach(async () => {
    await initEmojiMock();
  });

  afterEach(() => {
    window.gon = {};
    delete document.body.dataset.groupFullPath;
    clearEmojiMock();
  });

  describe('initEmojiMap', () => {
    it('should contain valid emoji', async () => {
      await initEmojiMap();

      const allEmoji = Object.keys(getEmojiMap());
      Object.keys(validEmoji).forEach((key) => {
        expect(allEmoji.includes(key)).toBe(true);
      });
    });

    it('should not contain invalid emoji', async () => {
      await initEmojiMap();

      const allEmoji = Object.keys(getEmojiMap());
      Object.keys(invalidEmoji).forEach((key) => {
        expect(allEmoji.includes(key)).toBe(false);
      });
    });
  });

  describe('glEmojiTag', () => {
    it('bomb emoji', () => {
      const emojiKey = 'bomb';
      const markup = glEmojiTag(emojiKey);

      expect(trimText(markup)).toMatchInlineSnapshot(`
        <gl-emoji
          data-name="bomb"
        />
      `);
    });

    it('bomb emoji with sprite fallback readiness', () => {
      const emojiKey = 'bomb';
      const markup = glEmojiTag(emojiKey, {
        sprite: true,
      });
      expect(trimText(markup)).toMatchInlineSnapshot(`
        <gl-emoji
          data-fallback-sprite-class="emoji-bomb"
          data-name="bomb"
        />
      `);
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
    beforeEach(() => {
      gon.emoji_backend_version = EMOJI_VERSION;
    });

    it('should gracefully handle empty string with unicode support', () => {
      const isSupported = isEmojiUnicodeSupported({ '1.0': true }, '', '1.0');

      expect(isSupported).toBe(true);
    });

    it('should gracefully handle empty string without unicode support', () => {
      const isSupported = isEmojiUnicodeSupported({}, '', '1.0');

      expect(isSupported).toBe(false);
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

    it('bomb(6.0) without 6.0 but with backend support', () => {
      gon.emoji_backend_version = EMOJI_VERSION + 1;
      const emojiKey = 'bomb';
      const unicodeSupportMap = emptySupportMap;
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
    });

    it('bomb(6.0) without 6.0 with empty backend version', () => {
      gon.emoji_backend_version = null;
      const emojiKey = 'bomb';
      const unicodeSupportMap = emptySupportMap;
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(false);
    });

    it('expressionless(6.1)', () => {
      const emojiKey = 'expressionless';
      const unicodeSupportMap = { ...emptySupportMap, 6.1: true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
    });

    it('spy(7.0)', () => {
      const emojiKey = 'spy';
      const unicodeSupportMap = { ...emptySupportMap, '7.0': true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
    });

    it('metal(8.0)', () => {
      const emojiKey = 'metal';
      const unicodeSupportMap = { ...emptySupportMap, '8.0': true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
    });

    it('rofl(9.0)', () => {
      const emojiKey = 'rofl';
      const unicodeSupportMap = { ...emptySupportMap, '9.0': true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
    });

    it('face_vomiting(10.0)', () => {
      const emojiKey = 'face_vomiting';
      const unicodeSupportMap = { ...emptySupportMap, '10.0': true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
    });

    it('man superhero(11.0)', () => {
      const emojiKey = 'man_superhero';
      const unicodeSupportMap = { ...emptySupportMap, '11.0': true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
    });

    it('person standing(12.0)', () => {
      const emojiKey = 'person_standing';
      const unicodeSupportMap = { ...emptySupportMap, '12.0': true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
    });

    it('person: red hair(12.1)', () => {
      const emojiKey = 'person_red_hair';
      const unicodeSupportMap = { ...emptySupportMap, 12.1: true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
    });

    it('people hugging(13.0)', () => {
      const emojiKey = 'people_hugging';
      const unicodeSupportMap = { ...emptySupportMap, '13.0': true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
    });

    it('face_with_spiral_eyes(13.1)', () => {
      const emojiKey = 'face_with_spiral_eyes';
      const unicodeSupportMap = { ...emptySupportMap, 13.1: true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
    });

    it('coral(14.0)', () => {
      const emojiKey = 'coral';
      const unicodeSupportMap = { ...emptySupportMap, '14.0': true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
    });

    it('jellyfish(15.0)', () => {
      const emojiKey = 'jellyfish';
      const unicodeSupportMap = { ...emptySupportMap, '15.0': true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
    });

    it('lime(15.1)', () => {
      gon.emoji_backend_version = null;
      const emojiKey = 'lime';
      const unicodeSupportMap = { ...emptySupportMap, 15.1: true };
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );

      expect(isSupported).toBe(true);
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
      expect(getEmojiInfo(name)).toEqual(getEmojiMap()[name]);
    });

    it('should return fallback emoji by default', () => {
      expect(getEmojiInfo('atjs')).toEqual(getEmojiMap().grey_question);
    });

    it('should return null when fallback is false', () => {
      expect(getEmojiInfo('atjs', false)).toBe(null);
    });

    describe('when query is undefined', () => {
      it('should return fallback emoji by default', () => {
        expect(getEmojiInfo()).toEqual(getEmojiMap().grey_question);
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
          if (name === EMOJI_THUMBS_UP) {
            score = 0.5;
          }

          // Negative intent value retrieved from ~/emoji/intents.json
          if (name === EMOJI_THUMBS_DOWN) {
            score = 1.5;
          }

          return {
            emoji: getEmojiMap()[name],
            field: 'd',
            fieldValue: getEmojiMap()[name].d,
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
          emoji: getEmojiMap()[name],
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
        'sym',
        [
          {
            name: 'atom',
            field: 'd',
            score: 32,
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
            field: 'd',
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
            name: EMOJI_THUMBS_UP,
            field: 'd',
            score: 0.5,
          },
          {
            name: EMOJI_THUMBS_DOWN,
            field: 'd',
            score: 1.5,
          },
        ],
      ],
    ])('should return a correct result when %s', (_, query, searchResult) => {
      const expected = searchResult.map((item) => {
        const { field, score, name } = item;
        return {
          emoji: getEmojiMap()[name],
          field,
          fieldValue: getEmojiMap()[name][field],
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

  describe('emojiFallbackImageSrc', () => {
    beforeEach(async () => {
      createMockEmojiClient();

      await initEmojiMock();
    });

    it.each`
      emoji              | src
      ${EMOJI_THUMBS_UP} | ${`/-/emojis/${EMOJI_VERSION}/${EMOJI_THUMBS_UP}.png`}
      ${'parrot'}        | ${'parrot.gif'}
    `('returns $src for emoji with name $emoji', ({ emoji, src }) => {
      expect(emojiFallbackImageSrc(emoji)).toBe(src);
    });
  });

  describe('loadCustomEmojiWithNames', () => {
    describe('when not in a group', () => {
      beforeEach(() => {
        createMockEmojiClient();
        delete document.body.dataset.groupFullPath;
      });

      it('returns empty emoji data', async () => {
        const result = await loadCustomEmojiWithNames();

        expect(result).toEqual({ emojis: {}, names: [] });
      });
    });

    describe('when GraphQL request returns null data', () => {
      beforeEach(() => {
        mockClient = createMockClient([
          [
            customEmojiQuery,
            jest.fn().mockResolvedValue({
              data: {
                group: null,
              },
            }),
          ],
        ]);
      });

      it('returns empty emoji data', async () => {
        const result = await loadCustomEmojiWithNames();

        expect(result).toEqual({ emojis: {}, names: [] });
      });
    });

    describe('when in a group', () => {
      it('returns emoji data', async () => {
        createMockEmojiClient();

        const result = await loadCustomEmojiWithNames();

        expect(result).toEqual({
          emojis: {
            parrot: {
              c: 'custom',
              d: 'parrot',
              e: undefined,
              name: 'parrot',
              src: 'parrot.gif',
              u: 'custom',
            },
          },
          names: ['parrot'],
        });
      });

      it('paginates custom emoji emoji', async () => {
        createMockEmojiClient(true);

        const result = await loadCustomEmojiWithNames();

        expect(result).toEqual({
          emojis: {
            parrot: {
              c: 'custom',
              d: 'parrot',
              e: undefined,
              name: 'parrot',
              src: 'parrot.gif',
              u: 'custom',
            },
            'parrot-test': {
              c: 'custom',
              d: 'parrot-test',
              e: undefined,
              name: 'parrot-test',
              src: 'parrot.gif',
              u: 'custom',
            },
          },
          names: ['parrot', 'parrot-test'],
        });
      });
    });
  });
});
