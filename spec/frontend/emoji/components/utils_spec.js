import { initEmojiMock } from 'helpers/emoji';
import { getFrequentlyUsedEmojis, addToFrequentlyUsed } from '~/emoji/components/utils';
import { EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN } from '~/emoji/constants';

describe('getFrequentlyUsedEmojis', () => {
  beforeAll(async () => {
    await initEmojiMock();
  });

  it('returns null when no saved emojis set', async () => {
    Storage.prototype.setItem = jest.fn();

    expect(await getFrequentlyUsedEmojis()).toBe(null);
  });

  it('returns frequently used emojis object', async () => {
    Storage.prototype.getItem = jest.fn(() => `${EMOJI_THUMBS_UP},${EMOJI_THUMBS_DOWN}`);

    const frequentlyUsed = await getFrequentlyUsedEmojis();

    expect(frequentlyUsed).toEqual({
      frequently_used: {
        emojis: [[EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN]],
        top: 0,
        height: 73,
      },
    });
  });

  it('only returns frequently used emojis that are in the possible emoji set', async () => {
    Storage.prototype.getItem = jest.fn(() => `${EMOJI_THUMBS_UP},${EMOJI_THUMBS_DOWN},ack`);

    const frequentlyUsed = await getFrequentlyUsedEmojis();

    expect(frequentlyUsed).toEqual({
      frequently_used: {
        emojis: [[EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN]],
        top: 0,
        height: 73,
      },
    });
  });
});

describe('addToFrequentlyUsed', () => {
  it('sets cookie value', () => {
    Storage.prototype.getItem = jest.fn(() => null);

    addToFrequentlyUsed(EMOJI_THUMBS_UP);

    expect(localStorage.setItem).toHaveBeenCalledWith('frequently_used_emojis', EMOJI_THUMBS_UP);
  });

  it('sets cookie value to include previously set cookie value', () => {
    Storage.prototype.getItem = jest.fn(() => EMOJI_THUMBS_DOWN);

    addToFrequentlyUsed(EMOJI_THUMBS_UP);

    expect(localStorage.setItem).toHaveBeenCalledWith(
      'frequently_used_emojis',
      `${EMOJI_THUMBS_DOWN},${EMOJI_THUMBS_UP}`,
    );
  });

  it('sets cookie value with uniq values', () => {
    Storage.prototype.getItem = jest.fn(() => EMOJI_THUMBS_UP);

    addToFrequentlyUsed(EMOJI_THUMBS_UP);

    expect(localStorage.setItem).toHaveBeenCalledWith('frequently_used_emojis', EMOJI_THUMBS_UP);
  });
});
