import { countBy } from 'lodash';
import { __ } from '~/locale';
import {
  getBaseURL,
  relativePathToAbsolute,
  setUrlParams,
  joinPaths,
} from '~/lib/utils/url_utility';
import { darkModeEnabled } from '~/lib/utils/color_utils';
import { setAttributes, isElementVisible } from '~/lib/utils/dom_utils';
import { createAlert, VARIANT_WARNING } from '~/alert';
import { unrestrictedPages } from './constants';

// Renders diagrams and flowcharts from text using Mermaid in any element with the
// `js-render-mermaid` class.
//
// Example markup:
//
// <pre class="js-render-mermaid">
//  graph TD;
//    A-- > B;
//    A-- > C;
//    B-- > D;
//    C-- > D;
// </pre>
//

const SANDBOX_FRAME_PATH = '/-/sandbox/mermaid';
// This is an arbitrary number; Can be iterated upon when suitable.
export const MAX_CHAR_LIMIT = 2000;
// Max # of mermaid blocks that can be rendered in a page.
export const MAX_MERMAID_BLOCK_LIMIT = 50;
// Max # of `&` allowed in Chaining of links syntax
const MAX_CHAINING_OF_LINKS_LIMIT = 30;

export const BUFFER_IFRAME_HEIGHT = 10;
export const SANDBOX_ATTRIBUTES = 'allow-scripts allow-popups';

const ALERT_CONTAINER_CLASS = 'mermaid-alert-container';
export const LAZY_ALERT_SHOWN_CLASS = 'lazy-alert-shown';

// Keep a map of mermaid blocks we've already rendered.
const elsProcessingMap = new WeakMap();
let renderedMermaidBlocks = 0;

/**
 * Determines whether a given Mermaid diagram is visible.
 *
 * @param {Element} el The Mermaid DOM node
 * @returns
 */
const isVisibleMermaid = (el) => el.closest('details') === null && isElementVisible(el);

function shouldLazyLoadMermaidBlock(source) {
  /**
   * If source contains `&`, which means that it might
   * contain Chaining of links a new syntax in Mermaid.
   */
  if (countBy(source)['&'] > MAX_CHAINING_OF_LINKS_LIMIT) {
    return true;
  }

  return false;
}

function fixElementSource(el) {
  // Mermaid doesn't like `<br />` tags, so collapse all like tags into `<br>`, which is parsed correctly.
  const source = el.textContent?.replace(/<br\s*\/>/g, '<br>');

  return { source };
}

export function getSandboxFrameSrc() {
  const path = joinPaths(gon.relative_url_root || '', SANDBOX_FRAME_PATH);
  let absoluteUrl = relativePathToAbsolute(path, getBaseURL());
  if (darkModeEnabled()) {
    absoluteUrl = setUrlParams({ darkMode: darkModeEnabled() }, absoluteUrl);
  }
  if (window.gon?.relative_url_root) {
    absoluteUrl = setUrlParams({ relativeRootPath: window.gon.relative_url_root }, absoluteUrl);
  }
  return absoluteUrl;
}

function renderMermaidEl(el, source) {
  const iframeEl = document.createElement('iframe');
  setAttributes(iframeEl, {
    src: getSandboxFrameSrc(),
    sandbox: SANDBOX_ATTRIBUTES,
    frameBorder: 0,
    scrolling: 'no',
    width: '100%',
  });

  const wrapper = document.createElement('div');
  wrapper.appendChild(iframeEl);

  // Hide the markdown but keep it "visible enough" to allow Copy-as-GFM
  // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/83202
  // Also remove padding from the pre element to prevent errant scrollbar appearing
  el.closest('pre').classList.add('gl-sr-only', '!gl-p-0');
  el.closest('pre').parentNode.appendChild(wrapper);

  // Event Listeners
  iframeEl.addEventListener('load', () => {
    // Potential risk associated with '*' discussed in below thread
    // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/74414#note_735183398
    iframeEl.contentWindow.postMessage(source, '*');
  });

  window.addEventListener(
    'message',
    (event) => {
      if (event.origin !== 'null' || event.source !== iframeEl.contentWindow) {
        return;
      }
      const { h } = event.data;
      iframeEl.height = `${h + BUFFER_IFRAME_HEIGHT}px`;
    },
    false,
  );
}

function renderMermaids(els) {
  if (!els.length) return;

  const pageName = document.querySelector('body').dataset.page;

  // A diagram may have been truncated in search results which will cause errors, so abort the render.
  if (pageName === 'search:show') return;

  let renderedChars = 0;

  els.forEach((el) => {
    // Skipping all the elements which we've already queued in requestIdleCallback
    if (elsProcessingMap.has(el)) {
      return;
    }

    const { source } = fixElementSource(el);
    /**
     * Restrict the rendering to a certain amount of character
     * and mermaid blocks to prevent mermaidjs from hanging
     * up the entire thread and causing a DoS.
     */
    if (
      !unrestrictedPages.includes(pageName) &&
      ((source && source.length > MAX_CHAR_LIMIT) ||
        renderedChars > MAX_CHAR_LIMIT ||
        renderedMermaidBlocks >= MAX_MERMAID_BLOCK_LIMIT ||
        shouldLazyLoadMermaidBlock(source))
    ) {
      const parent = el.parentNode;

      if (!parent.classList.contains(LAZY_ALERT_SHOWN_CLASS)) {
        const alertContainer = document.createElement('div');
        alertContainer.classList.add(ALERT_CONTAINER_CLASS);
        alertContainer.classList.add('gl-mb-5');
        parent.before(alertContainer);
        createAlert({
          message: __(
            'Warning: Displaying this diagram might cause performance issues on this page.',
          ),
          variant: VARIANT_WARNING,
          parent: parent.parentNode,
          containerSelector: `.${ALERT_CONTAINER_CLASS}`,
          primaryButton: {
            text: __('Display'),
            clickHandler: () => {
              alertContainer.remove();
              renderMermaidEl(el, source);
            },
          },
        });
        parent.classList.add(LAZY_ALERT_SHOWN_CLASS);
      }

      return;
    }

    renderedChars += source.length;
    renderedMermaidBlocks += 1;

    const requestId = window.requestIdleCallback(() => {
      renderMermaidEl(el, source);
    });

    elsProcessingMap.set(el, requestId);
  });
}

export default function renderMermaid(els) {
  if (!els.length) return;

  const visibleMermaids = [];
  const hiddenMermaids = [];

  for (const el of els) {
    if (isVisibleMermaid(el)) {
      visibleMermaids.push(el);
    } else {
      hiddenMermaids.push(el);
    }
  }

  renderMermaids(visibleMermaids);

  hiddenMermaids.forEach((el) => {
    el.closest('details')?.addEventListener(
      'toggle',
      ({ target: details }) => {
        if (details.open) {
          renderMermaids([...details.querySelectorAll('.js-render-mermaid')]);
        }
      },
      {
        once: true,
      },
    );
  });
}
