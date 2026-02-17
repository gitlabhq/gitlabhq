import { createWrapper } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import renderMermaid, {
  MAX_CHAR_LIMIT,
  MAX_MERMAID_BLOCK_LIMIT,
  LAZY_ALERT_SHOWN_CLASS,
} from '~/behaviors/markdown/render_sandboxed_mermaid';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';

jest.mock('~/panel_breakpoint_instance', () => ({
  PanelBreakpointInstance: {
    addResizeListener: jest.fn(),
    removeResizeListener: jest.fn(),
  },
}));

describe('Mermaid diagrams renderer', () => {
  // Finders
  const findMermaidIframes = () => document.querySelectorAll('iframe[src*="/-/sandbox/mermaid"]');
  const findDangerousMermaidAlert = () =>
    createWrapper(document.querySelector('[data-testid="alert-warning"]'));

  // Helpers
  const renderDiagrams = (selector = '.js-render-mermaid') => {
    renderMermaid([...document.querySelectorAll(selector)]);
    jest.runAllTimers();
  };

  beforeEach(() => {
    document.body.dataset.page = '';
    jest.clearAllMocks();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('rendering mermaid diagrams', () => {
    it.each`
      description                          | fixture                                                                                                                             | selector
      ${'with js-render-mermaid class'}    | ${'<div class="gl-relative markdown-code-block js-markdown-code"><pre><code class="js-render-mermaid">graph LR</code></pre></div>'} | ${'.js-render-mermaid'}
      ${'with language class on code tag'} | ${'<div class="js-markdown-code"><pre><code class="language-mermaid">graph LR</code></pre></div>'}                                  | ${'code.language-mermaid'}
    `('renders a mermaid diagram $description', ({ fixture, selector }) => {
      setHTMLFixture(fixture);

      expect(findMermaidIframes()).toHaveLength(0);

      renderDiagrams(selector);

      expect(document.querySelector('pre').classList).toContain('gl-sr-only');
      expect(findMermaidIframes()).toHaveLength(1);
    });
  });

  describe('within a details element', () => {
    beforeEach(() => {
      setHTMLFixture('<details><pre><code class="js-render-mermaid"></code></pre></details>');
      renderDiagrams();
    });

    it('does not render the diagram on load', () => {
      expect(findMermaidIframes()).toHaveLength(0);
    });

    it('render the diagram when the details element is opened', () => {
      document.querySelector('details').setAttribute('open', true);
      document.querySelector('details').dispatchEvent(new Event('toggle'));
      jest.runAllTimers();

      expect(findMermaidIframes()).toHaveLength(1);
    });
  });

  describe('dangerous diagrams', () => {
    describe(`when the diagram's source exceeds ${MAX_CHAR_LIMIT} characters`, () => {
      beforeEach(() => {
        setHTMLFixture(
          `<pre>
            <code class="js-render-mermaid">${Array(MAX_CHAR_LIMIT + 1)
              .fill('a')
              .join('')}</code>
          </pre>`,
        );
        renderDiagrams();
      });
      it('does not render the diagram on load', () => {
        expect(findMermaidIframes()).toHaveLength(0);
      });

      it('shows a warning about performance impact when rendering the diagram', () => {
        expect(document.querySelector('pre').classList).toContain(LAZY_ALERT_SHOWN_CLASS);
        expect(findDangerousMermaidAlert().exists()).toBe(true);
        expect(findDangerousMermaidAlert().text()).toContain(
          'Warning: Displaying this diagram might cause performance issues on this page.',
        );
      });

      it("renders the diagram when clicking on the alert's button", () => {
        findDangerousMermaidAlert().find('button').trigger('click');
        jest.runAllTimers();

        expect(findMermaidIframes()).toHaveLength(1);
      });
    });

    it(`stops rendering diagrams once the total rendered source exceeds ${MAX_CHAR_LIMIT} characters`, () => {
      setHTMLFixture(
        `<pre>
          <code class="js-render-mermaid">${Array(MAX_CHAR_LIMIT - 1)
            .fill('a')
            .join('')}</code>
          <code class="js-render-mermaid">2</code>
          <code class="js-render-mermaid">3</code>
          <code class="js-render-mermaid">4</code>
        </pre>`,
      );
      renderDiagrams();

      expect(findMermaidIframes()).toHaveLength(3);
    });

    // Note: The test case below is provided for convenience but should remain skipped as the DOM
    // operations it requires are too expensive and would significantly slow down the test suite.
    // eslint-disable-next-line jest/no-disabled-tests
    it.skip(`stops rendering diagrams when the rendered diagrams count exceeds ${MAX_MERMAID_BLOCK_LIMIT}`, () => {
      setHTMLFixture(
        `<pre>
          ${Array(MAX_MERMAID_BLOCK_LIMIT + 1)
            .fill('<code class="js-render-mermaid"></code>')
            .join('')}
        </pre>`,
      );
      renderDiagrams();

      expect([...document.querySelectorAll('.js-render-mermaid')]).toHaveLength(
        MAX_MERMAID_BLOCK_LIMIT + 1,
      );
      expect(findMermaidIframes()).toHaveLength(MAX_MERMAID_BLOCK_LIMIT);
    });
  });

  describe('does not render mermaid diagrams without a parent element', () => {
    it('does not render when code element has no pre parent', () => {
      const orphanedCode = document.createElement('code');
      orphanedCode.classList.add('language-mermaid');
      orphanedCode.textContent = 'graph LR';

      renderMermaid([orphanedCode]);
      jest.runAllTimers();

      expect(findMermaidIframes()).toHaveLength(0);
    });
  });

  describe('resize handling', () => {
    it('adds a resize listener when rendering a diagram', () => {
      setHTMLFixture('<pre><code class="js-render-mermaid">graph LR</code></pre>');

      renderDiagrams();

      expect(PanelBreakpointInstance.addResizeListener).toHaveBeenCalled();
    });

    it('removes resize listener when wrapper is removed from DOM', () => {
      setHTMLFixture('<pre><code class="js-render-mermaid">graph LR</code></pre>');

      renderDiagrams();

      const resizeHandler = PanelBreakpointInstance.addResizeListener.mock.calls[0][0];

      // Remove wrapper from DOM
      const wrapper = document.querySelector('iframe').parentNode;
      wrapper.remove();

      // Trigger resize handler
      resizeHandler();
      jest.runAllTimers();

      expect(PanelBreakpointInstance.removeResizeListener).toHaveBeenCalledWith(resizeHandler);
    });
  });
});
