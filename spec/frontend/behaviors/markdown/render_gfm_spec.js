import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { renderGlql } from '~/behaviors/markdown/render_glql';
import { renderJSONTable } from '~/behaviors/markdown/render_json_table';
import { renderImageLightbox } from '~/behaviors/markdown/render_image_lightbox';

jest.mock('~/behaviors/markdown/render_glql', () => ({
  renderGlql: jest.fn(),
}));

jest.mock('~/behaviors/markdown/render_json_table', () => ({
  renderJSONTable: jest.fn(),
  renderJSONTableHTML: jest.fn(),
}));

jest.mock('~/behaviors/markdown/render_image_lightbox', () => ({
  renderImageLightbox: jest.fn(),
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
    });

    it.each`
      description                             | innerHTML                                                                                                               | selector
      ${'with data-canonical-lang data attr'} | ${'<div class="gl-relative markdown-code-block"><pre data-canonical-lang="glql"><code>labels = any</code></pre></div>'} | ${'[data-canonical-lang="glql"]'}
      ${'with language class on code tag'}    | ${'<div><pre><code class="language-glql">labels = any</code></pre></div>'}                                              | ${'.language-glql'}
    `('calls renderGlql $description', ({ innerHTML, selector }) => {
      element.innerHTML = innerHTML;

      renderGFM(element);

      expect(renderGlql).toHaveBeenCalledWith([element.querySelector(selector)]);
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

  describe('rendering image lightboxes', () => {
    let element;

    beforeEach(() => {
      element = document.createElement('div');
      element.innerHTML = `
        <a href="image1.jpg"><img src="image1.jpg" alt="Image 1"></a>
        <a href="image2.png"><img src="image2.png" alt="Image 2"></a>
        <a href="https://example.com/image3.gif"><img src="image3.gif" alt="Image 3"></a>
      `;
    });

    it('calls renderImageLightbox with image elements and container', () => {
      renderGFM(element);

      const images = Array.from(element.querySelectorAll('a>img'));
      expect(renderImageLightbox).toHaveBeenCalledWith(images, element);
    });
  });
});
