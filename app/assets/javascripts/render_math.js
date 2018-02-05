import { __ } from './locale';
import flash from './flash';

// Renders math using KaTeX in any element with the
// `js-render-math` class
//
// ### Example Markup
//
//   <code class="js-render-math"></div>
//

// Loop over all math elements and render math
function renderWithKaTeX(elements, katex) {
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
  import(/* webpackChunkName: 'katex' */ 'katex').then((katex) => {
    import(/* webpackChunkName: 'katex' */ 'katex/dist/katex.css')
    .then(() => {
      renderWithKaTeX($els, katex);
    })
    .catch((err) => {
      flash(`Can't load katex css ${err}`);
    });
  }).catch(() => flash(__('An error occurred while rendering KaTeX')));
}
