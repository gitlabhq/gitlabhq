/* global katex */

// Renders math using KaTeX in any element with the
// `js-render-math` class
//
// ### Example Markup
//
//   <code class="js-render-math"></div>
//
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
    $.get(gon.katex_css_url, () => {
      const css = $('<link>', {
        rel: 'stylesheet',
        type: 'text/css',
        href: gon.katex_css_url,
      });
      css.appendTo('head');

      // Load KaTeX js
      $.getScript(gon.katex_js_url, () => {
        katexLoaded = true;
        renderWithKaTeX($els); // Run KaTeX
      });
    });
  }
}
