import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { renderGlql } from '~/behaviors/markdown/render_glql';

jest.mock('~/behaviors/markdown/render_glql', () => ({
  renderGlql: jest.fn(),
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

    describe('when glqlIntegration is enabled', () => {
      beforeEach(() => {
        gon.features = { glqlIntegration: true };
      });

      it('calls renderGlql', () => {
        renderGFM(element);

        expect(renderGlql).toHaveBeenCalledWith([element.firstElementChild]);
      });
    });

    describe('when glqlIntegration is disabled', () => {
      beforeEach(() => {
        gon.features = { glqlIntegration: false };
      });

      it('does not call renderGlql', () => {
        renderGFM(element);

        expect(renderGlql).not.toHaveBeenCalled();
      });
    });
  });
});
