$.fn.syntaxHighlight = function() {
  var $children;
  if ($(this).hasClass('js-syntax-highlight')) {
    return $(this).addClass(gon.user_color_scheme);
  } else {
    $children = $(this).find('.js-syntax-highlight');
    if ($children.length) {
      return $children.syntaxHighlight();
    }
  }
};

$(document).on('ready page:load', function() {
  return $('.js-syntax-highlight').syntaxHighlight();
});
