(function() {
  $(function() {
    return $("body").on("click", ".js-toggle-button", function(e) {
      $(this).find('i').toggleClass('fa fa-chevron-down').toggleClass('fa fa-chevron-up');
      $(this).closest(".js-toggle-container").find(".js-toggle-content").toggle();
      return e.preventDefault();
    });
  });

}).call(this);
