import {
  renderUneditableLeaf,
  renderUneditableBranch,
} from '~/vue_shared/components/rich_content_editor/services/renderers/render_utils';

import {
  buildUneditableBlockTokens,
  buildUneditableOpenTokens,
} from '~/vue_shared/components/rich_content_editor/services/renderers/build_uneditable_token';

import { originToken, uneditableCloseToken } from './mock_data';

describe('Render utils', () => {
  describe('renderUneditableLeaf', () => {
    it('should return uneditable block tokens around an origin token', () => {
      const context = { origin: jest.fn().mockReturnValueOnce(originToken) };
      const result = renderUneditableLeaf({}, context);

      expect(result).toStrictEqual(buildUneditableBlockTokens(originToken));
    });
  });

  describe('renderUneditableBranch', () => {
    let origin;

    beforeEach(() => {
      origin = jest.fn().mockReturnValueOnce(originToken);
    });

    it('should return uneditable block open token followed by the origin token when entering', () => {
      const context = { entering: true, origin };
      const result = renderUneditableBranch({}, context);

      expect(result).toStrictEqual(buildUneditableOpenTokens(originToken));
    });

    it('should return uneditable block closing token when exiting', () => {
      const context = { entering: false, origin };
      const result = renderUneditableBranch({}, context);

      expect(result).toStrictEqual(uneditableCloseToken);
    });
  });
});
