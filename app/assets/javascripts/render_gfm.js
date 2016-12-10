// Render Gitlab flavoured Markdown
//
// Delegates to syntax highlight and render math
//
(function() {
  $.fn.renderGFM = function() {
    $(this).find('.js-syntax-highlight').syntaxHighlight();
    $(this).find('.js-render-math').renderMath();
  };

  $(document).on('ready page:load', function() {
    return $('body').renderGFM();
  });

}).call(this);
