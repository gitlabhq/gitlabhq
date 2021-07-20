import $ from 'jquery';
import { once, countBy } from 'lodash';
import createFlash from '~/flash';
import { darkModeEnabled } from '~/lib/utils/color_utils';
import { __, sprintf } from '~/locale';

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

// This is an arbitrary number; Can be iterated upon when suitable.
const MAX_CHAR_LIMIT = 2000;
// Max # of mermaid blocks that can be rendered in a page.
const MAX_MERMAID_BLOCK_LIMIT = 50;
// Max # of `&` allowed in Chaining of links syntax
const MAX_CHAINING_OF_LINKS_LIMIT = 30;
// Keep a map of mermaid blocks we've already rendered.
const elsProcessingMap = new WeakMap();
let renderedMermaidBlocks = 0;

let mermaidModule = {};

// Whitelist pages where we won't impose any restrictions
// on mermaid rendering
const WHITELISTED_PAGES = [
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

export function initMermaid(mermaid) {
  let theme = 'neutral';

  if (darkModeEnabled()) {
    theme = 'dark';
  }

  mermaid.initialize({
    // mermaid core options
    mermaid: {
      startOnLoad: false,
    },
    // mermaidAPI options
    theme,
    flowchart: {
      useMaxWidth: true,
      htmlLabels: true,
    },
    securityLevel: 'strict',
  });

  return mermaid;
}

function importMermaidModule() {
  return import(/* webpackChunkName: 'mermaid' */ 'mermaid')
    .then((mermaid) => {
      mermaidModule = initMermaid(mermaid);
    })
    .catch((err) => {
      createFlash({
        message: sprintf(__("Can't load mermaid module: %{err}"), { err }),
      });
      // eslint-disable-next-line no-console
      console.error(err);
    });
}

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
  const source = el.textContent.replace(/<br\s*\/>/g, '<br>');

  // Remove any extra spans added by the backend syntax highlighting.
  Object.assign(el, { textContent: source });

  return { source };
}

function renderMermaidEl(el) {
  mermaidModule.init(undefined, el, (id) => {
    const source = el.textContent;
    const svg = document.getElementById(id);

    // As of https://github.com/knsv/mermaid/commit/57b780a0d,
    // Mermaid will make two init callbacks:one to initialize the
    // flow charts, and another to initialize the Gannt charts.
    // Guard against an error caused by double initialization.
    if (svg.classList.contains('mermaid')) {
      return;
    }

    svg.classList.add('mermaid');

    // pre > code > svg
    svg.closest('pre').replaceWith(svg);

    // We need to add the original source into the DOM to allow Copy-as-GFM
    // to access it.
    const sourceEl = document.createElement('text');
    sourceEl.classList.add('source');
    sourceEl.setAttribute('display', 'none');
    sourceEl.textContent = source;

    svg.appendChild(sourceEl);
  });
}

function renderMermaids($els) {
  if (!$els.length) return;

  const pageName = document.querySelector('body').dataset.page;

  // A diagram may have been truncated in search results which will cause errors, so abort the render.
  if (pageName === 'search:show') return;

  importMermaidModule()
    .then(() => {
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
          !WHITELISTED_PAGES.includes(pageName) &&
          ((source && source.length > MAX_CHAR_LIMIT) ||
            renderedChars > MAX_CHAR_LIMIT ||
            renderedMermaidBlocks >= MAX_MERMAID_BLOCK_LIMIT ||
            shouldLazyLoadMermaidBlock(source))
        ) {
          const html = `
          <div class="alert gl-alert gl-alert-warning alert-dismissible lazy-render-mermaid-container js-lazy-render-mermaid-container fade show" role="alert">
            <div>
              <div class="display-flex">
                <div>${__(
                  'Warning: Displaying this diagram might cause performance issues on this page.',
                )}</div>
                <div class="gl-alert-actions">
                  <button class="js-lazy-render-mermaid btn gl-alert-action btn-warning btn-md gl-button">Display</button>
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
            $parent.addClass('lazy-alert-shown');
          }

          return;
        }

        renderedChars += source.length;
        renderedMermaidBlocks += 1;

        const requestId = window.requestIdleCallback(() => {
          renderMermaidEl(el);
        });

        elsProcessingMap.set(el, requestId);
      });
    })
    .catch((err) => {
      createFlash({
        message: sprintf(__('Encountered an error while rendering: %{err}'), { err }),
      });
      // eslint-disable-next-line no-console
      console.error(err);
    });
}

const hookLazyRenderMermaidEvent = once(() => {
  $(document.body).on('click', '.js-lazy-render-mermaid', function eventHandler() {
    const parent = $(this).closest('.js-lazy-render-mermaid-container');
    const pre = parent.prev();

    const el = pre.find('.js-render-mermaid');

    parent.remove();

    renderMermaidEl(el);
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
