import { getInitialEditingMode } from '~/vue_shared/components/markdown/utils';

const EDITING_MODE_KEY = 'gl-markdown-editor-mode';

describe('~/vue_shared/components/markdown/utils', () => {
  describe('getInitialEditingMode', () => {
    afterEach(() => {
      localStorage.clear();
    });

    it.each`
      preference             | expected
      ${'rich_text_editor'}  | ${'contentEditor'}
      ${'plain_text_editor'} | ${'markdownField'}
    `('returns $expected for the $preference preference', ({ preference, expected }) => {
      window.gon = { text_editor: preference };

      expect(getInitialEditingMode()).toBe(expected);
    });

    it('ignores the stored mode when a preference is set', () => {
      window.gon = { text_editor: 'plain_text_editor' };
      localStorage.setItem(EDITING_MODE_KEY, 'contentEditor');

      expect(getInitialEditingMode()).toBe('markdownField');
    });

    describe('without a preference', () => {
      beforeEach(() => {
        window.gon = {};
      });

      it('restores the stored mode', () => {
        localStorage.setItem(EDITING_MODE_KEY, 'contentEditor');

        expect(getInitialEditingMode()).toBe('contentEditor');
      });

      it('falls back to the markdown field when nothing is stored', () => {
        expect(getInitialEditingMode()).toBe('markdownField');
      });
    });
  });
});
