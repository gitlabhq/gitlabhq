import $ from 'jquery';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import renderMermaid from '~/behaviors/markdown/render_sandboxed_mermaid';

describe('Render mermaid diagrams for Gitlab Flavoured Markdown', () => {
  it('Does something', () => {
    document.body.dataset.page = '';
    setHTMLFixture(`
      <div class="gl-relative markdown-code-block js-markdown-code">
        <pre data-sourcepos="1:1-7:3" class="code highlight js-syntax-highlight language-mermaid white" lang="mermaid" id="code-4">
          <code class="js-render-mermaid">
            <span id="LC1" class="line" lang="mermaid">graph TD;</span>
            <span id="LC2" class="line" lang="mermaid">A--&gt;B</span>
            <span id="LC3" class="line" lang="mermaid">A--&gt;C</span>
            <span id="LC4" class="line" lang="mermaid">B--&gt;D</span>
            <span id="LC5" class="line" lang="mermaid">C--&gt;D</span>
          </code>
        </pre>
        <copy-code>
          <button type="button" class="btn btn-default btn-md gl-button btn-icon has-tooltip" data-title="Copy to clipboard" data-clipboard-target="pre#code-4">
            <svg><use xlink:href="/assets/icons-7f1680a3670112fe4c8ef57b9dfb93f0f61b43a2a479d7abd6c83bcb724b9201.svg#copy-to-clipboard"></use></svg>
          </button>
        </copy-code>
      </div>`);
    const els = $('pre.js-syntax-highlight').find('.js-render-mermaid');

    renderMermaid(els);

    jest.runAllTimers();
    expect(document.querySelector('pre.js-syntax-highlight').classList).toContain('gl-sr-only');

    resetHTMLFixture();
  });
});
