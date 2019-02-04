/* eslint-disable consistent-return, no-else-return */

import $ from 'jquery';

// Syntax Highlighter
//
// Applies a syntax highlighting color scheme CSS class to any element with the
// `js-syntax-highlight` class
//
// ### Example Markup
//
//   <div class="js-syntax-highlight"></div>
//

export default function syntaxHighlight(el) {
  if ($(el).hasClass('js-syntax-highlight')) {
    // Given the element itself, apply highlighting
    return $(el).addClass(gon.user_color_scheme);
  } else {
    // Given a parent element, recurse to any of its applicable children
    const $children = $(el).find('.js-syntax-highlight');
    if ($children.length) {
      return syntaxHighlight($children);
    }
  }
}
