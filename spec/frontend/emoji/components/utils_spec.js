import Cookies from '~/lib/utils/cookies';
import { getFrequentlyUsedEmojis, addToFrequentlyUsed } from '~/emoji/components/utils';

jest.mock('~/lib/utils/cookies');

describe('getFrequentlyUsedEmojis', () => {
  it('returns null when no saved emojis set', () => {
    jest.spyOn(Cookies, 'get').mockReturnValue(null);

    expect(getFrequentlyUsedEmojis()).toBe(null);
  });

  it('returns frequently used emojis object', () => {
    jest.spyOn(Cookies, 'get').mockReturnValue('thumbsup,thumbsdown');

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
    jest.spyOn(Cookies, 'get').mockReturnValue(null);

    addToFrequentlyUsed('thumbsup');

    expect(Cookies.set).toHaveBeenCalledWith('frequently_used_emojis', 'thumbsup', {
      expires: 365,
      secure: false,
    });
  });

  it('sets cookie value to include previously set cookie value', () => {
    jest.spyOn(Cookies, 'get').mockReturnValue('thumbsdown');

    addToFrequentlyUsed('thumbsup');

    expect(Cookies.set).toHaveBeenCalledWith('frequently_used_emojis', 'thumbsdown,thumbsup', {
      expires: 365,
      secure: false,
    });
  });

  it('sets cookie value with uniq values', () => {
    jest.spyOn(Cookies, 'get').mockReturnValue('thumbsup');

    addToFrequentlyUsed('thumbsup');

    expect(Cookies.set).toHaveBeenCalledWith('frequently_used_emojis', 'thumbsup', {
      expires: 365,
      secure: false,
    });
  });
});
