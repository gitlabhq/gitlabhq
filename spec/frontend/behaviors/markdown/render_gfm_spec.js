import initIssuablePopovers from '~/issuable/popover';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { renderGlql } from '~/behaviors/markdown/render_glql';
import { renderJSONTable } from '~/behaviors/markdown/render_json_table';
import { renderImageLightbox } from '~/behaviors/markdown/render_image_lightbox';
import renderSandboxedMermaid from '~/behaviors/markdown/render_sandboxed_mermaid';
import renderMarkdownTables from '~/behaviors/markdown/render_markdown_tables';
import waitForPromises from 'helpers/wait_for_promises';

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

jest.mock('~/behaviors/markdown/render_sandboxed_mermaid', () => jest.fn());

// Spy on renderMarkdownTables while keeping the real implementation, so the tests
// below can observe what the rest of renderGFM sees once a table has been mounted.
jest.mock('~/behaviors/markdown/render_markdown_tables', () => {
  const { default: renderMarkdownTablesActual } = jest.requireActual(
    '~/behaviors/markdown/render_markdown_tables',
  );

  return { __esModule: true, default: jest.fn(renderMarkdownTablesActual) };
});

jest.mock('~/issuable/popover', () => ({ __esModule: true, default: jest.fn() }));

describe('renderGFM', () => {
  it('handles a missing element', () => {
    expect(() => {
      renderGFM();
    }).not.toThrow();
  });

  describe('rendering a mermaid block', () => {
    let element;

    beforeEach(() => {
      element = document.createElement('div');
    });

    it.each`
      description                          | innerHTML                                                                                                                                        | selector
      ${'with js-render-mermaid class'}    | ${'<div class="gl-relative markdown-code-block"><pre data-canonical-lang="mermaid"><code class="js-render-mermaid">graph LR</code></pre></div>'} | ${'.js-render-mermaid'}
      ${'with language class on code tag'} | ${'<div><pre><code class="language-mermaid">graph LR</code></pre></div>'}                                                                        | ${'code.language-mermaid'}
    `('calls renderSandboxedMermaid $description', ({ innerHTML, selector }) => {
      element.innerHTML = innerHTML;

      renderGFM(element);

      expect(renderSandboxedMermaid).toHaveBeenCalledWith([element.querySelector(selector)]);
    });
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

  describe('rendering markdown', () => {
    let element;

    beforeEach(() => {
      element = document.createElement('div');
      element.innerHTML = `
        <div class="md">
          <table>
            <thead><tr><th>Header 1</th><th>Header 2</th></tr></thead>
            <tbody><tr><td>Data 1</td><td>Data 2</td></tr></tbody>
          </table>
          <table class="code">
            <thead><tr><th>Code Header</th></tr></thead>
            <tbody><tr><td>Code Data</td></tr></tbody>
          </table>
        </div>
      `;
    });

    it('calls renderMarkdownTables with markdown tables, excluding code tables', () => {
      renderGFM(element);

      const tables = Array.from(element.querySelectorAll('.md table:not(.code)'));
      expect(tables).toHaveLength(1);
      expect(renderMarkdownTables).toHaveBeenCalledWith(tables);
    });
  });

  describe('rendering markdown containing a table which is itself rendered', () => {
    let element;

    beforeEach(() => {
      window.gon = { features: { markdownSortableTableColumns: true } };

      element = document.createElement('div');
      element.innerHTML = `
        <div class="md">
          <table>
            <thead><tr><th>Reference</th><th>Image</th></tr></thead>
            <tbody>
              <tr>
                <td>
                  <a href="/g/p/-/issues/1" class="gfm gfm-issue" data-reference-type="issue">#1</a>
                </td>
                <td>
                  <a href="/uploads/image.png"><img src="/uploads/image.png" alt="Image"></a>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      `;
      document.body.appendChild(element);
    });

    afterEach(() => {
      element.remove();
    });

    it('initialises popovers on the references present in the final DOM', async () => {
      renderGFM(element);
      await waitForPromises();

      const reference = element.querySelector('.gfm-issue');
      expect(reference).not.toBe(null);

      expect(initIssuablePopovers).toHaveBeenCalled();
      const [references] = initIssuablePopovers.mock.calls.at(-1);
      expect(references).toHaveLength(1);
      expect(references[0].isConnected).toBe(true);
      expect(references[0]).toBe(reference);
    });

    it('renders image lightboxes for the images present in the final DOM', async () => {
      renderGFM(element);
      await waitForPromises();

      const image = element.querySelector('img');
      expect(image).not.toBe(null);

      expect(renderImageLightbox).toHaveBeenCalled();
      const [images] = renderImageLightbox.mock.calls.at(-1);
      expect(images).toHaveLength(1);
      expect(images[0].isConnected).toBe(true);
      expect(images[0]).toBe(image);
    });
  });
});
