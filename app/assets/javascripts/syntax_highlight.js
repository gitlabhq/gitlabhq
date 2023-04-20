// Syntax Highlighter
//
// Applies a syntax highlighting color scheme CSS class to any element with the
// `js-syntax-highlight` class
//
// ### Example Markup
//
//   <div class="js-syntax-highlight"></div>
//

export default function syntaxHighlight($els = null) {
  if (!$els || $els.length === 0) return;

  const els = $els.get ? $els.get() : $els;
  // eslint-disable-next-line consistent-return
  const handler = (el) => {
    if (el.classList === undefined) {
      return el;
    }

    if (el.classList.contains('js-syntax-highlight')) {
      // Given the element itself, apply highlighting
      return el.classList.add(gon.user_color_scheme);
    }
    // Given a parent element, recurse to any of its applicable children
    const children = el.querySelectorAll('.js-syntax-highlight');
    if (children.length) {
      return syntaxHighlight(children);
    }
  };

  // In order to account for NodeList returned by document.querySelectorAll,
  // we should rather check whether the els object is iterable
  // instead of relying on Array.isArray()
  const isIterable = typeof els[Symbol.iterator] === 'function';

  if (isIterable) {
    els.forEach((el) => handler(el));
  } else {
    handler(els);
  }
}
