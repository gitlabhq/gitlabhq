import { TEST_HOST } from 'spec/test_constants';
import {
  DEFAULT_SIZE_CLASS,
  IDENTICON_BG_COUNT,
  renderAvatar,
  renderIdenticon,
  getIdenticonBackgroundClass,
  getIdenticonTitle,
} from '~/helpers/avatar_helper';
import { getFirstCharacterCapitalized } from '~/lib/utils/text_utility';

function matchAll(str) {
  return new RegExp(`^${str}$`);
}

describe('avatar_helper', () => {
  describe('getIdenticonBackgroundClass', () => {
    it('returns identicon bg class from id that is a number', () => {
      expect(getIdenticonBackgroundClass(1)).toEqual('bg2');
    });

    it('returns identicon bg class from id that is a string', () => {
      expect(getIdenticonBackgroundClass('1')).toEqual('bg2');
    });

    it('returns identicon bg class from id that is a GraphQL string id', () => {
      expect(getIdenticonBackgroundClass('gid://gitlab/Project/1')).toEqual('bg2');
    });

    it('returns identicon bg class from unparsable string', () => {
      expect(getIdenticonBackgroundClass('gid://gitlab/')).toEqual('bg1');
    });

    it(`wraps around if id is bigger than ${IDENTICON_BG_COUNT}`, () => {
      expect(getIdenticonBackgroundClass(IDENTICON_BG_COUNT + 4)).toEqual('bg5');
      expect(getIdenticonBackgroundClass(IDENTICON_BG_COUNT * 5 + 6)).toEqual('bg7');
    });
  });

  describe('getIdenticonTitle', () => {
    it('returns identicon title from name', () => {
      expect(getIdenticonTitle('Lorem')).toEqual('L');
      expect(getIdenticonTitle('dolar-sit-amit')).toEqual('D');
      expect(getIdenticonTitle('%-with-special-chars')).toEqual('%');
    });

    it('returns space if name is falsey', () => {
      expect(getIdenticonTitle('')).toEqual(' ');
      expect(getIdenticonTitle(null)).toEqual(' ');
    });
  });

  describe('renderIdenticon', () => {
    it('renders with the first letter as title and bg based on id', () => {
      const entity = {
        id: IDENTICON_BG_COUNT + 3,
        name: 'Xavior',
      };
      const options = {
        sizeClass: 's32',
      };

      const result = renderIdenticon(entity, options);

      expect(result).toHaveClass(`identicon ${options.sizeClass} bg4`);
      expect(result).toHaveText(matchAll(getFirstCharacterCapitalized(entity.name)));
    });

    it('renders with defaults, if no options are given', () => {
      const entity = {
        id: 1,
        name: 'tanuki',
      };

      const result = renderIdenticon(entity);

      expect(result).toHaveClass(`identicon ${DEFAULT_SIZE_CLASS} bg2`);
      expect(result).toHaveText(matchAll(getFirstCharacterCapitalized(entity.name)));
    });
  });

  describe('renderAvatar', () => {
    it('renders an image with the avatarUrl', () => {
      const avatarUrl = `${TEST_HOST}/not-real-assets/test.png`;

      const result = renderAvatar({
        avatar_url: avatarUrl,
      });

      expect(result).toBeMatchedBy('img');
      expect(result).toHaveAttr('src', avatarUrl);
      expect(result).toHaveClass(DEFAULT_SIZE_CLASS);
    });

    it('renders an identicon if no avatarUrl', () => {
      const entity = {
        id: 1,
        name: 'walrus',
      };
      const options = {
        sizeClass: 's16',
      };

      const result = renderAvatar(entity, options);

      expect(result).toHaveClass(`identicon ${options.sizeClass} bg2`);
      expect(result).toHaveText(matchAll(getFirstCharacterCapitalized(entity.name)));
    });
  });
});
