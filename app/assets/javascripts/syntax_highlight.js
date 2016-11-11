/* eslint-disable */
// Syntax Highlighter
//
// Applies a syntax highlighting color scheme CSS class to any element with the
// `js-syntax-highlight` class
//
// ### Example Markup
//
//   <div class="js-syntax-highlight"></div>
//
(function() {
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

  $(document).on('ready page:load', function() {
    return $('.js-syntax-highlight').syntaxHighlight();
  });

}).call(this);
