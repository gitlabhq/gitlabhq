import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { renderGlql } from '~/behaviors/markdown/render_glql';
import { renderJSONTable } from '~/behaviors/markdown/render_json_table';

jest.mock('~/behaviors/markdown/render_glql', () => ({
  renderGlql: jest.fn(),
}));

jest.mock('~/behaviors/markdown/render_json_table', () => ({
  renderJSONTable: jest.fn(),
  renderJSONTableHTML: jest.fn(),
}));

describe('renderGFM', () => {
  it('handles a missing element', () => {
    expect(() => {
      renderGFM();
    }).not.toThrow();
  });

  describe('rendering a glql block', () => {
    let element;

    beforeEach(() => {
      element = document.createElement('div');
      element.innerHTML =
        '<div class="gl-relative markdown-code-block"><pre data-canonical-lang="glql"><code>labels = any</code></pre></div>';
    });

    it('calls renderGlql', () => {
      renderGFM(element);

      expect(renderGlql).toHaveBeenCalledWith([element.firstElementChild]);
    });
  });

  describe('rendering a json table', () => {
    let element;

    beforeEach(() => {
      element = document.createElement('div');
      element.innerHTML =
        '<div class="gl-relative markdown-code-block"><pre data-canonical-lang="json" data-lang-params="table"><code>{"items": [{"description": "foo"}]}</code></pre></div>';
    });

    describe('when a json table is detected', () => {
      it('calls renderJSONTable', () => {
        renderGFM(element);

        expect(renderJSONTable).toHaveBeenCalledWith([element.firstElementChild]);
      });
    });
  });
});
