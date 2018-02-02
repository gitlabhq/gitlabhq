/* global katex */

// Renders math using KaTeX in any element with the
// `js-render-math` class
//
// ### Example Markup
//
//   <code class="js-render-math"></div>
//

import { __ } from './locale';
import axios from './lib/utils/axios_utils';
import flash from './flash';

// Only load once
let katexLoaded = false;

// Loop over all math elements and render math
function renderWithKaTeX(elements) {
  elements.each(function katexElementsLoop() {
    const mathNode = $('<span></span>');
    const $this = $(this);

    const display = $this.attr('data-math-style') === 'display';
    try {
      katex.render($this.text(), mathNode.get(0), { displayMode: display, throwOnError: false });
      mathNode.insertAfter($this);
      $this.remove();
    } catch (err) {
      throw err;
    }
  });
}

export default function renderMath($els) {
  if (!$els.length) return;

  if (katexLoaded) {
    renderWithKaTeX($els);
  } else {
    axios.get(gon.katex_css_url)
      .then(() => {
        const css = $('<link>', {
          rel: 'stylesheet',
          type: 'text/css',
          href: gon.katex_css_url,
        });
        css.appendTo('head');
      })
      .then(() => axios.get(gon.katex_js_url, {
        responseType: 'text',
      }))
      .then(({ data }) => {
        // Add katex js to our document
        $.globalEval(data);
      })
      .then(() => {
        katexLoaded = true;
        renderWithKaTeX($els); // Run KaTeX
      })
      .catch(() => flash(__('An error occurred while rendering KaTeX')));
  }
}
