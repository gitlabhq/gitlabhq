this.Aside = (function() {
  function Aside() {
    $(document).off("click", "a.show-aside");
    $(document).on("click", 'a.show-aside', function(e) {
      var btn, icon;
      e.preventDefault();
      btn = $(e.currentTarget);
      icon = btn.find('i');
      if (icon.hasClass('fa-angle-left')) {
        btn.parent().find('section').hide();
        btn.parent().find('aside').fadeIn();
        return icon.removeClass('fa-angle-left').addClass('fa-angle-right');
      } else {
        btn.parent().find('aside').hide();
        btn.parent().find('section').fadeIn();
        return icon.removeClass('fa-angle-right').addClass('fa-angle-left');
      }
    });
  }

  return Aside;

})();
