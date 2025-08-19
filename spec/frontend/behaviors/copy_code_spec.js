import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initCopyCodeButton } from '~/behaviors/copy_code';

describe('Copy Code Button', () => {
  let mockObserver;
  let observerCallback;

  beforeEach(() => {
    mockObserver = {
      observe: jest.fn(),
      disconnect: jest.fn(),
    };

    window.MutationObserver = jest.fn((callback) => {
      observerCallback = callback;
      return mockObserver;
    });
  });

  const getBodyHTML = () => document.body.innerHTML;

  const findElement = () => document.querySelector('.js-markdown-code copy-code');
  const findButton = () => document.querySelector('.js-markdown-code copy-code button');

  const findAllButtons = () => document.querySelectorAll('.js-markdown-code copy-code button');

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('initCopyCodeButton', () => {
    it('defines a <copy-code> custom element (only once)', () => {
      jest.spyOn(window.customElements, 'define');

      initCopyCodeButton();
      initCopyCodeButton();

      expect(window.customElements.define).toHaveBeenCalledWith('copy-code', expect.any(Function));
      expect(window.customElements.define).toHaveBeenCalledTimes(1);

      window.customElements.define.mockRestore();
    });

    describe('sets up mutation observer', () => {
      let mockObserve;

      beforeEach(() => {
        mockObserve = jest.fn();
        jest.spyOn(window, 'MutationObserver').mockImplementation(() => {
          return { observe: mockObserve };
        });
      });

      afterEach(() => {
        window.MutationObserver.mockRestore();
      });

      it('sets up MutationObserver on default selector', () => {
        setHTMLFixture('<div id="content-body"></div>');

        initCopyCodeButton();

        expect(MutationObserver).toHaveBeenCalledWith(expect.any(Function));
        expect(mockObserve).toHaveBeenCalledWith(document.querySelector('#content-body'), {
          childList: true,
          subtree: true,
        });
      });

      it('sets up MutationObserver on custom selector', () => {
        setHTMLFixture('<div class="custom-selector"></div>');

        initCopyCodeButton('.custom-selector');

        expect(mockObserve).toHaveBeenCalledWith(document.querySelector('.custom-selector'), {
          childList: true,
          subtree: true,
        });
      });
    });

    describe('when target element does not exist', () => {
      beforeEach(() => {
        jest.spyOn(window, 'MutationObserver');
      });

      afterEach(() => {
        MutationObserver.mockRestore();
      });

      it('does not create element', () => {
        setHTMLFixture('<div></div>');

        initCopyCodeButton();

        expect(MutationObserver).not.toHaveBeenCalled();
        expect(getBodyHTML()).toMatchInterpolatedText('<div></div>');
      });

      it('does not create element for raw file content', () => {
        setHTMLFixture('<div id="content-body"></div> <div class="file-content code"></div>');

        initCopyCodeButton();

        expect(MutationObserver).not.toHaveBeenCalled();
        expect(getBodyHTML()).toMatchInterpolatedText(
          '<div id="content-body"></div> <div class="file-content code"></div>',
        );
      });
    });
  });

  describe('addCodeButton functionality', () => {
    it('shows button for a <pre>', () => {
      setHTMLFixture(`
        <div id="content-body">
          <pre class="code js-syntax-highlight" lang="javascript">
            <code>console.log('test');</code>
          </pre>
        </div>
      `);

      initCopyCodeButton();
      observerCallback();

      expect(findElement()).not.toBeNull();

      expect([...findButton().classList]).toEqual(
        expect.arrayContaining([
          'btn',
          'btn-default',
          'btn-md',
          'gl-button',
          'btn-icon',
          'has-tooltip',
        ]),
      );
      expect(findButton().getAttribute('aria-label')).toEqual('Copy to clipboard');
      expect(findButton().dataset.title).toEqual('Copy to clipboard');
      expect(findButton().dataset.clipboardTarget).toEqual('pre#code-2');

      expect(document.querySelector(findButton().dataset.clipboardTarget).innerText.trim()).toBe(
        "console.log('test');",
      );
    });

    it('shows multiple buttons for multiple <pre> elements', () => {
      setHTMLFixture(`
        <div id="content-body">
          <pre class="code js-syntax-highlight" lang="javascript">
            <code>console.log('test1');</code>
          </pre>
          <pre class="code js-syntax-highlight" lang="python">
            <code>print('test2')</code>
          </pre>
        </div>
      `);

      initCopyCodeButton();
      observerCallback();

      expect(findAllButtons()).toHaveLength(2);

      expect(
        document.querySelector(findAllButtons()[0].dataset.clipboardTarget).innerText.trim(),
      ).toBe("console.log('test1');");
      expect(
        document.querySelector(findAllButtons()[1].dataset.clipboardTarget).innerText.trim(),
      ).toBe("print('test2')");
    });

    it('ignores elements wrapped in .md-suggestion containers', () => {
      setHTMLFixture(`
        <div id="content-body">
          <div class="md-suggestion">
            <pre class="code js-syntax-highlight" lang="javascript">
              <code>console.log('test');</code>
            </pre>
          </div>
        </div>
      `);

      initCopyCodeButton();
      observerCallback();

      expect(findButton()).toBeNull();
    });

    it('ignores mermaid elements', () => {
      setHTMLFixture(`
        <div id="content-body">
          <pre class="code js-syntax-highlight" lang="mermaid">
            <code>graph TD; A-->B;</code>
          </pre>
        </div>
      `);

      initCopyCodeButton();
      observerCallback();

      expect(findButton()).toBeNull();
    });

    it('ignores elements already in .js-markdown-code containers', () => {
      setHTMLFixture(`
        <div id="content-body">
          <div class="js-markdown-code">
            <pre class="code js-syntax-highlight" lang="javascript">
              <code>console.log('test');</code>
            </pre>
          </div>
        </div>
      `);

      initCopyCodeButton();
      observerCallback();

      expect(findButton()).toBeNull();
    });

    it('filters out content-editor-code-block elements', () => {
      setHTMLFixture(`
        <div id="content-body">
          <pre class="code js-syntax-highlight content-editor-code-block" lang="javascript">
            <code>console.log('test');</code>
          </pre>
        </div>
      `);

      initCopyCodeButton();
      observerCallback();

      expect(findButton()).toBeNull();
    });
  });
});
