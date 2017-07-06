/* eslint-disable func-names, space-before-function-paren, consistent-return, no-var, no-else-return, prefer-arrow-callback, max-len */

// Syntax Highlighter
//
// Applies a syntax highlighting color scheme CSS class to any element with the
// `js-syntax-highlight` class
//
// ### Example Markup
//
//   <div class="js-syntax-highlight"></div>
//

$.fn.syntaxHighlight = function() {
  var $children;

  if ($(this).hasClass('js-syntax-highlight')) {
    // Given the element itself, apply highlighting
    return $(this).addClass(gon.user_color_scheme);
  } else {
    // Given a parent element, recurse to any of its applicable children
    $children = $(this).find('.js-syntax-highlight');
    if ($children.length) {
      return $children.syntaxHighlight();
    }
  }
};
