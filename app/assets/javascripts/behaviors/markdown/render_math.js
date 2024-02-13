import { escape } from 'lodash';
import { spriteIcon } from '~/lib/utils/common_utils';
import { differenceInMilliseconds } from '~/lib/utils/datetime_utility';
import { s__, sprintf } from '~/locale';

// Renders math using KaTeX in an element.
//
// Typically for elements with the `js-render-math` class such as
//   <code class="js-render-math"></code>
//
// See app/assets/javascripts/behaviors/markdown/render_gfm.js

const MAX_MATH_CHARS = 1000;
const MAX_MACRO_EXPANSIONS = 1000;
const MAX_USER_SPECIFIED_EMS = 20;
const MAX_RENDER_TIME_MS = 2000;

// Wait for the browser to reflow the layout. Reflowing SVG takes time.
// This has to wrap the inner function, otherwise IE/Edge throw "invalid calling object".
const waitForReflow = (fn) => {
  window.requestIdleCallback(fn);
};

const katexOptions = (el) => {
  const options = {
    displayMode: el.dataset.mathStyle === 'display',
    throwOnError: true,
    trust: (context) =>
      // this config option restores the KaTeX pre-v0.11.0
      // behavior of allowing certain commands and protocols
      // eslint-disable-next-line @gitlab/require-i18n-strings
      ['\\url', '\\href'].includes(context.command) &&
      ['http', 'https', 'mailto', '_relative'].includes(context.protocol),
  };

  if (gon.math_rendering_limits_enabled) {
    options.maxSize = MAX_USER_SPECIFIED_EMS;
    // See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111107 for
    // reasoning behind this value
    options.maxExpand = MAX_MACRO_EXPANSIONS;
  } else {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    options.maxExpand = 'Infinity';
  }

  return options;
};

/**
 * Renders math blocks sequentially while protecting against DoS attacks. Math blocks have a maximum character limit of MAX_MATH_CHARS. If rendering math takes longer than MAX_RENDER_TIME_MS, all subsequent math blocks are skipped and an error message is shown.
 */
class SafeMathRenderer {
  /*
  How this works:

  The performance bottleneck in rendering math is in the browser trying to reflow the generated SVG.
  During this time, the JS is blocked and the page becomes unresponsive.
  We want to render math blocks one by one until a certain time is exceeded, after which we stop
  rendering subsequent math blocks, to protect against DoS. However, browsers do reflowing in an
  asynchronous task, so we can't time it synchronously.

  SafeMathRenderer essentially does the following:
  1. Replaces all math blocks with placeholders so that they're not mistakenly rendered twice.
  2. Places each placeholder element in a queue.
  3. Renders the element at the head of the queue and waits for reflow.
  4. After reflow, gets the elapsed time since step 3 and repeats step 3 until the queue is empty.
   */
  queue = [];
  totalMS = 0;

  constructor(elements, katex) {
    this.elements = elements;
    this.katex = katex;

    this.renderElement = this.renderElement.bind(this);
    this.render = this.render.bind(this);
    this.attachEvents = this.attachEvents.bind(this);
    this.pageName = document.querySelector('body').dataset.page;
  }

  renderElement(chosenEl) {
    if (!this.queue.length && !chosenEl) {
      return;
    }

    const el = chosenEl || this.queue.shift();
    const forceRender = Boolean(chosenEl) || !gon.math_rendering_limits_enabled;
    const text = el.textContent;

    el.removeAttribute('style');
    if (!forceRender && (this.totalMS >= MAX_RENDER_TIME_MS || text.length > MAX_MATH_CHARS)) {
      // Show un-rendered math code
      const codeElement = document.createElement('pre');

      codeElement.className = 'code';
      codeElement.textContent = el.textContent;
      codeElement.dataset.mathStyle = el.dataset.mathStyle;

      let message;
      if (text.length > MAX_MATH_CHARS) {
        message = sprintf(
          s__(
            'math|This math block exceeds %{maxMathChars} characters, and may cause performance issues on this page.',
          ),
          { maxMathChars: MAX_MATH_CHARS },
        );
      } else {
        message = s__('math|Displaying this math block may cause performance issues on this page.');
      }

      const html = `
          <div class="alert gl-alert gl-alert-warning alert-dismissible lazy-render-math-container js-lazy-render-math-container fade show" role="alert">
            ${spriteIcon('warning', 'gl-text-orange-600 s16 gl-alert-icon')}
            <div class="display-flex gl-alert-content">
              <div>${message}</div>
              <div class="gl-alert-actions">
                <button class="js-lazy-render-math btn gl-alert-action btn-confirm btn-md gl-button">Display anyway</button>
              </div>
            </div>
            <button type="button" class="close js-close" aria-label="Close">
              ${spriteIcon('close', 's16')}
            </button>
          </div>
          `;

      if (!el.classList.contains('lazy-alert-shown')) {
        // eslint-disable-next-line no-unsanitized/property
        el.innerHTML = html;
        el.append(codeElement);
        el.classList.add('lazy-alert-shown');
      }

      // Render the next math
      this.renderElement();
    } else {
      this.startTime = Date.now();

      /* Get the correct reference to the display container when:
       * a.) Happy path: when the math block is present, and
       * b.) When we've replace the block with <pre> for lazy rendering
       */
      let displayContainer = el;
      if (el.tagName === 'PRE') {
        displayContainer = el.parentElement;
      }

      try {
        if (displayContainer.dataset.mathStyle === 'inline') {
          displayContainer.classList.add('math-content-inline');
        } else {
          displayContainer.classList.add('math-content-display');
        }

        // eslint-disable-next-line no-unsanitized/property
        displayContainer.innerHTML = this.katex.renderToString(text, katexOptions(el));
      } catch (e) {
        // Don't show a flash for now because it would override an existing flash message
        if (e.message.match(/Too many expansions/)) {
          // this is controlled by the maxExpand parameter
          el.textContent = s__('math|Too many expansions. Consider using multiple math blocks.');
        } else {
          // According to https://katex.org/docs/error.html, we need to ensure that
          // the error message is escaped.
          el.textContent = sprintf(
            s__('math|There was an error rendering this math block. %{katexMessage}'),
            { katexMessage: escape(e.message) },
          );
        }
        el.className = 'katex-error';
      }

      // Give the browser time to reflow the svg
      waitForReflow(() => {
        const deltaTime = differenceInMilliseconds(this.startTime);
        this.totalMS += deltaTime;

        this.renderElement();
      });
    }
  }

  render() {
    // Replace math blocks with a placeholder so they aren't rendered twice
    this.elements.forEach((el) => {
      const placeholder = document.createElement('div');
      placeholder.dataset.mathStyle = el.dataset.mathStyle;
      placeholder.textContent = el.textContent;
      el.parentNode.replaceChild(placeholder, el);
      this.queue.push(placeholder);
    });

    // If we wait for the browser thread to settle down a bit, math rendering becomes 5-10x faster
    // and less prone to timeouts.
    setTimeout(this.renderElement, 400);
  }

  attachEvents() {
    document.body.addEventListener('click', (event) => {
      const alert = event.target.closest('.js-lazy-render-math-container');

      if (!alert) {
        return;
      }

      // Handle alert close
      if (event.target.closest('.js-close')) {
        alert.remove();
        return;
      }

      // Handle "render anyway"
      if (event.target.classList.contains('js-lazy-render-math')) {
        const pre = alert.nextElementSibling;
        alert.remove();
        this.renderElement(pre);
      }
    });
  }
}

export default function renderMath(elements) {
  if (!elements.length) return;
  Promise.all([
    import(/* webpackChunkName: 'katex' */ 'katex'),
    import(/* webpackChunkName: 'katex' */ 'katex/dist/katex.min.css'),
  ])
    .then(([katex]) => {
      const renderer = new SafeMathRenderer(elements, katex);
      renderer.render();
      renderer.attachEvents();
    })
    .catch(() => {});
}
