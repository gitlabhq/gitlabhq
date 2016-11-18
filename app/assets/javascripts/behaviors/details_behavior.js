/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, quotes, no-var, vars-on-top, padded-blocks, max-len */
(function() {
  $(function() {
    $("body").on("click", ".js-details-target", function() {
      var container;
      container = $(this).closest(".js-details-container");
      return container.toggleClass("open");
    });
    // Show details content. Hides link after click.
    //
    // %div
    //   %a.js-details-expand
    //   %div.js-details-content
    //
    return $("body").on("click", ".js-details-expand", function(e) {
      $(this).next('.js-details-content').removeClass("hide");
      $(this).hide();

      var truncatedItem = $(this).siblings('.js-details-short');
      if (truncatedItem.length) {
        truncatedItem.addClass("hide");
      }
      return e.preventDefault();
    });
  });

}).call(this);
