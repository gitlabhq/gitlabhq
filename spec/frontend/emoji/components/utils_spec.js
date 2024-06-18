import { getFrequentlyUsedEmojis, addToFrequentlyUsed } from '~/emoji/components/utils';

describe('getFrequentlyUsedEmojis', () => {
  it('returns null when no saved emojis set', () => {
    Storage.prototype.setItem = jest.fn();

    expect(getFrequentlyUsedEmojis()).toBe(null);
  });

  it('returns frequently used emojis object', () => {
    Storage.prototype.getItem = jest.fn(() => 'thumbsup,thumbsdown');

    expect(getFrequentlyUsedEmojis()).toEqual({
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
