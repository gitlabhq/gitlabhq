import $ from 'jquery';
import { once, countBy } from 'lodash';
import { __ } from '~/locale';
import {
  getBaseURL,
  relativePathToAbsolute,
  setUrlParams,
  joinPaths,
} from '~/lib/utils/url_utility';
import { darkModeEnabled } from '~/lib/utils/color_utils';
import { setAttributes } from '~/lib/utils/dom_utils';

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
const MAX_CHAR_LIMIT = 2000;
// Max # of mermaid blocks that can be rendered in a page.
const MAX_MERMAID_BLOCK_LIMIT = 50;
// Max # of `&` allowed in Chaining of links syntax
const MAX_CHAINING_OF_LINKS_LIMIT = 30;
const BUFFER_IFRAME_HEIGHT = 10;
// Keep a map of mermaid blocks we've already rendered.
const elsProcessingMap = new WeakMap();
let renderedMermaidBlocks = 0;

// Pages without any restrictions on mermaid rendering
const PAGES_WITHOUT_RESTRICTIONS = [
  // Group wiki
  'groups:wikis:show',
  'groups:wikis:edit',
  'groups:wikis:create',

  // Project wiki
  'projects:wikis:show',
  'projects:wikis:edit',
  'projects:wikis:create',

  // Project files
  'projects:show',
  'projects:blob:show',
];

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

  // Remove any extra spans added by the backend syntax highlighting.
  Object.assign(el, { textContent: source });

  return { source };
}

function getSandboxFrameSrc() {
  const path = joinPaths(gon.relative_url_root || '', SANDBOX_FRAME_PATH);
  if (!darkModeEnabled()) {
    return path;
  }
  const absoluteUrl = relativePathToAbsolute(path, getBaseURL());
  return setUrlParams({ darkMode: darkModeEnabled() }, absoluteUrl);
}

function renderMermaidEl(el, source) {
  const iframeEl = document.createElement('iframe');
  setAttributes(iframeEl, {
    src: getSandboxFrameSrc(),
    sandbox: 'allow-scripts allow-popups',
    frameBorder: 0,
    scrolling: 'no',
    width: '100%',
  });

  // Add the original source into the DOM
  // to allow Copy-as-GFM to access it.
  const sourceEl = document.createElement('text');
  sourceEl.textContent = source;
  sourceEl.classList.add('gl-display-none');

  const wrapper = document.createElement('div');
  wrapper.appendChild(iframeEl);
  wrapper.appendChild(sourceEl);

  el.closest('pre').replaceWith(wrapper);

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

function renderMermaids($els) {
  if (!$els.length) return;

  const pageName = document.querySelector('body').dataset.page;

  // A diagram may have been truncated in search results which will cause errors, so abort the render.
  if (pageName === 'search:show') return;

  let renderedChars = 0;

  $els.each((i, el) => {
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
      !PAGES_WITHOUT_RESTRICTIONS.includes(pageName) &&
      ((source && source.length > MAX_CHAR_LIMIT) ||
        renderedChars > MAX_CHAR_LIMIT ||
        renderedMermaidBlocks >= MAX_MERMAID_BLOCK_LIMIT ||
        shouldLazyLoadMermaidBlock(source))
    ) {
      const html = `
          <div class="alert gl-alert gl-alert-warning alert-dismissible lazy-render-mermaid-container js-lazy-render-mermaid-container fade show" role="alert">
            <div>
              <div>
                <div class="js-warning-text"></div>
                <div class="gl-alert-actions">
                  <button type="button" class="js-lazy-render-mermaid btn gl-alert-action btn-warning btn-md gl-button">Display</button>
                </div>
              </div>
              <button type="button" class="close" data-dismiss="alert" aria-label="Close">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>
          </div>
          `;

      const $parent = $(el).parent();

      if (!$parent.hasClass('lazy-alert-shown')) {
        $parent.after(html);
        $parent
          .siblings()
          .find('.js-warning-text')
          .text(
            __('Warning: Displaying this diagram might cause performance issues on this page.'),
          );
        $parent.addClass('lazy-alert-shown');
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

const hookLazyRenderMermaidEvent = once(() => {
  $(document.body).on('click', '.js-lazy-render-mermaid', function eventHandler() {
    const parent = $(this).closest('.js-lazy-render-mermaid-container');
    const pre = parent.prev();

    const el = pre.find('.js-render-mermaid');

    parent.remove();

    // sandbox update
    const element = el.get(0);
    const { source } = fixElementSource(element);

    renderMermaidEl(element, source);
  });
});

export default function renderMermaid($els) {
  if (!$els.length) return;

  const visibleMermaids = $els.filter(function filter() {
    return $(this).closest('details').length === 0 && $(this).is(':visible');
  });

  renderMermaids(visibleMermaids);

  $els.closest('details').one('toggle', function toggle() {
    if (this.open) {
      renderMermaids($(this).find('.js-render-mermaid'));
    }
  });

  hookLazyRenderMermaidEvent();
}
