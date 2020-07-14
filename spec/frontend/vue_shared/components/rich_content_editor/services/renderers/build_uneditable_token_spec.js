import {
  buildUneditableOpenTokens,
  buildUneditableCloseToken,
  buildUneditableCloseTokens,
  buildUneditableInlineTokens,
  buildUneditableTokens,
} from '~/vue_shared/components/rich_content_editor/services/renderers/build_uneditable_token';

import {
  originInlineToken,
  originToken,
  uneditableOpenTokens,
  uneditableCloseToken,
  uneditableCloseTokens,
  uneditableInlineTokens,
  uneditableTokens,
} from './mock_data';

describe('Build Uneditable Token renderer helper', () => {
  describe('buildUneditableOpenTokens', () => {
    it('returns a 2-item array of tokens with the originToken appended to an open token', () => {
      const result = buildUneditableOpenTokens(originToken);

      expect(result).toHaveLength(2);
      expect(result).toStrictEqual(uneditableOpenTokens);
    });
  });

  describe('buildUneditableCloseToken', () => {
    it('returns an object literal representing the uneditable close token', () => {
      expect(buildUneditableCloseToken()).toStrictEqual(uneditableCloseToken);
    });
  });

  describe('buildUneditableCloseTokens', () => {
    it('returns a 2-item array of tokens with the originToken prepended to a close token', () => {
      const result = buildUneditableCloseTokens(originToken);

      expect(result).toHaveLength(2);
      expect(result).toStrictEqual(uneditableCloseTokens);
    });
  });

  describe('buildUneditableInlineTokens', () => {
    it('returns a 3-item array of tokens with the originInlineToken wrapped in the middle of inline tokens', () => {
      const result = buildUneditableInlineTokens(originInlineToken);

      expect(result).toHaveLength(3);
      expect(result).toStrictEqual(uneditableInlineTokens);
    });
  });

  describe('buildUneditableTokens', () => {
    it('returns a 3-item array of tokens with the originToken wrapped in the middle of block tokens', () => {
      const result = buildUneditableTokens(originToken);

      expect(result).toHaveLength(3);
      expect(result).toStrictEqual(uneditableTokens);
    });
  });
});
