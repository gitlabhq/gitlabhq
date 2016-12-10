// Render Gitlab flavoured Markdown
//
// Delegates to syntax highlight and render math
//
// ### Example Markup
//
//   <div class="js-syntax-highlight"></div>
//
(function() {
  $.fn.renderGFM = function() {
    console.log("GFM!");
    $(this).find('.js-syntax-highlight').syntaxHighlight();
    $(this).renderMath();
  };

  $(document).on('ready page:load', function() {
    return $('body').renderGFM();
  });

}).call(this);
