import {
  buildTextToken,
  buildUneditableOpenTokens,
  buildUneditableCloseToken,
  buildUneditableCloseTokens,
  buildUneditableBlockTokens,
  buildUneditableInlineTokens,
  buildUneditableHtmlAsTextTokens,
} from '~/static_site_editor/rich_content_editor/services/renderers/build_uneditable_token';

import {
  originInlineToken,
  originToken,
  uneditableOpenTokens,
  uneditableCloseToken,
  uneditableCloseTokens,
  uneditableBlockTokens,
  uneditableInlineTokens,
  uneditableTokens,
} from './mock_data';

describe('Build Uneditable Token renderer helper', () => {
  describe('buildTextToken', () => {
    it('returns an object literal representing a text token', () => {
      const text = originToken.content;
      expect(buildTextToken(text)).toStrictEqual(originToken);
    });
  });

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

  describe('buildUneditableBlockTokens', () => {
    it('returns a 3-item array of tokens with the originToken wrapped in the middle of block tokens', () => {
      const result = buildUneditableBlockTokens(originToken);

      expect(result).toHaveLength(3);
      expect(result).toStrictEqual(uneditableTokens);
    });
  });

  describe('buildUneditableInlineTokens', () => {
    it('returns a 3-item array of tokens with the originInlineToken wrapped in the middle of inline tokens', () => {
      const result = buildUneditableInlineTokens(originInlineToken);

      expect(result).toHaveLength(3);
      expect(result).toStrictEqual(uneditableInlineTokens);
    });
  });

  describe('buildUneditableHtmlAsTextTokens', () => {
    it('returns a 3-item array of tokens with the htmlBlockNode wrapped as a text token in the middle of block tokens', () => {
      const htmlBlockNode = {
        type: 'htmlBlock',
        literal: '<div data-tomark-pass ><h1>Some header</h1><p>Some paragraph</p></div>',
      };
      const result = buildUneditableHtmlAsTextTokens(htmlBlockNode);
      const { type, content } = result[1];

      expect(type).toBe('text');
      expect(content).not.toMatch(/ data-tomark-pass /);

      expect(result).toHaveLength(3);
      expect(result).toStrictEqual(uneditableBlockTokens);
    });
  });
});
