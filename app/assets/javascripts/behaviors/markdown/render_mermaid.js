import $ from 'jquery';
import { once } from 'lodash';
import { deprecatedCreateFlash as flash } from '~/flash';
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
const MAX_CHAR_LIMIT = 5000;
let mermaidModule = {};

function importMermaidModule() {
  return import(/* webpackChunkName: 'mermaid' */ 'mermaid')
    .then(mermaid => {
      let theme = 'neutral';
      const ideDarkThemes = ['dark', 'solarized-dark', 'monokai'];

      if (
        ideDarkThemes.includes(window.gon?.user_color_scheme) &&
        // if on the Web IDE page
        document.querySelector('.ide')
      ) {
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
          htmlLabels: false,
        },
        securityLevel: 'strict',
      });

      mermaidModule = mermaid;

      return mermaid;
    })
    .catch(err => {
      flash(sprintf(__("Can't load mermaid module: %{err}"), { err }));
      // eslint-disable-next-line no-console
      console.error(err);
    });
}

function fixElementSource(el) {
  // Mermaid doesn't like `<br />` tags, so collapse all like tags into `<br>`, which is parsed correctly.
  const source = el.textContent.replace(/<br\s*\/>/g, '<br>');

  // Remove any extra spans added by the backend syntax highlighting.
  Object.assign(el, { textContent: source });

  return { source };
}

function renderMermaidEl(el) {
  mermaidModule.init(undefined, el, id => {
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

  // A diagram may have been truncated in search results which will cause errors, so abort the render.
  if (document.querySelector('body').dataset.page === 'search:show') return;

  importMermaidModule()
    .then(() => {
      let renderedChars = 0;

      $els.each((i, el) => {
        const { source } = fixElementSource(el);
        /**
         * Restrict the rendering to a certain amount of character to
         * prevent mermaidjs from hanging up the entire thread and
         * causing a DoS.
         */
        if ((source && source.length > MAX_CHAR_LIMIT) || renderedChars > MAX_CHAR_LIMIT) {
          const html = `
          <div class="alert gl-alert gl-alert-warning alert-dismissible lazy-render-mermaid-container js-lazy-render-mermaid-container fade show" role="alert">
            <div>
              <div class="display-flex">
                <div>${__(
                  'Warning: Displaying this diagram might cause performance issues on this page.',
                )}</div>
                <div class="gl-alert-actions">
                  <button class="js-lazy-render-mermaid btn gl-alert-action btn-warning btn-md new-gl-button">Display</button>
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

        renderMermaidEl(el);
      });
    })
    .catch(err => {
      flash(sprintf(__('Encountered an error while rendering: %{err}'), { err }));
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
