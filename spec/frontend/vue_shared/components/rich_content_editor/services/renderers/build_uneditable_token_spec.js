import {
  buildUneditableOpenTokens,
  buildUneditableCloseToken,
  buildUneditableTokens,
} from '~/vue_shared/components/rich_content_editor/services/renderers//build_uneditable_token';

import {
  originToken,
  uneditableOpenTokens,
  uneditableCloseToken,
  uneditableTokens,
} from '../../mock_data';

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

  describe('buildUneditableTokens', () => {
    it('returns a 3-item array of tokens with the originToken wrapped in the middle', () => {
      const result = buildUneditableTokens(originToken);

      expect(result).toHaveLength(3);
      expect(result).toStrictEqual(uneditableTokens);
    });
  });
});
