import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import renderMath from '~/behaviors/markdown/render_math';

jest.mock('katex', () => ({ renderToString: jest.fn(() => '<span class="katex">x</span>') }));

describe('renderMath', () => {
  // Longer than MAX_MATH_CHARS, so the renderer shows the lazy-render alert instead of rendering.
  const tooLongMath = 'x'.repeat(1001);

  const findPlaceholder = () => document.querySelector('[data-math-style]');
  const findAlertBefore = (el) => el.previousElementSibling;

  const render = async () => {
    renderMath(document.querySelectorAll('.js-render-math'));
    await waitForPromises();
    jest.runAllTimers();
  };

  beforeEach(() => {
    gon.math_rendering_limits_enabled = true;
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when a too long math block is inside a code block wrapper', () => {
    beforeEach(() => {
      setHTMLFixture(`
        <div class="js-markdown-code">
          <pre><code class="js-render-math" data-math-style="display">${tooLongMath}</code></pre>
        </div>
      `);
    });

    it('mounts the alert before the wrapper', async () => {
      await render();

      const wrapper = document.querySelector('.js-markdown-code');

      expect(findAlertBefore(wrapper).textContent).toContain('This math block exceeds');
    });
  });

  describe('when a too long math block is inline, without a code block wrapper', () => {
    beforeEach(() => {
      setHTMLFixture(
        `<p>Some text <code class="js-render-math" data-math-style="inline">${tooLongMath}</code></p>`,
      );
    });

    it('does not throw and mounts the alert before the math block itself', async () => {
      await expect(render()).resolves.toBeUndefined();

      expect(findAlertBefore(findPlaceholder()).textContent).toContain('This math block exceeds');
    });
  });
});
