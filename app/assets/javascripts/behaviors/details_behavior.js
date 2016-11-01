/* eslint-disable */
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
      return e.preventDefault();
    });
  });

}).call(this);
