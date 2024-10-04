import { initEmojiMock } from 'helpers/emoji';
import { getFrequentlyUsedEmojis, addToFrequentlyUsed } from '~/emoji/components/utils';

describe('getFrequentlyUsedEmojis', () => {
  beforeAll(async () => {
    await initEmojiMock();
  });

  it('returns null when no saved emojis set', async () => {
    Storage.prototype.setItem = jest.fn();

    expect(await getFrequentlyUsedEmojis()).toBe(null);
  });

  it('returns frequently used emojis object', async () => {
    Storage.prototype.getItem = jest.fn(() => 'thumbsup,thumbsdown');

    const frequentlyUsed = await getFrequentlyUsedEmojis();

    expect(frequentlyUsed).toEqual({
      frequently_used: {
        emojis: [['thumbsup', 'thumbsdown']],
        top: 0,
        height: 71,
      },
    });
  });

  it('only returns frequently used emojis that are in the possible emoji set', async () => {
    Storage.prototype.getItem = jest.fn(() => 'thumbsup,thumbsdown,ack');

    const frequentlyUsed = await getFrequentlyUsedEmojis();

    expect(frequentlyUsed).toEqual({
      frequently_used: {
        emojis: [['thumbsup', 'thumbsdown']],
        top: 0,
        height: 71,
      },
    });
  });
});

describe('addToFrequentlyUsed', () => {
  it('sets cookie value', () => {
    Storage.prototype.getItem = jest.fn(() => null);

    addToFrequentlyUsed('thumbsup');

    expect(localStorage.setItem).toHaveBeenCalledWith('frequently_used_emojis', 'thumbsup');
  });

  it('sets cookie value to include previously set cookie value', () => {
    Storage.prototype.getItem = jest.fn(() => 'thumbsdown');

    addToFrequentlyUsed('thumbsup');

    expect(localStorage.setItem).toHaveBeenCalledWith(
      'frequently_used_emojis',
      'thumbsdown,thumbsup',
    );
  });

  it('sets cookie value with uniq values', () => {
    Storage.prototype.getItem = jest.fn(() => 'thumbsup');

    addToFrequentlyUsed('thumbsup');

    expect(localStorage.setItem).toHaveBeenCalledWith('frequently_used_emojis', 'thumbsup');
  });
});
