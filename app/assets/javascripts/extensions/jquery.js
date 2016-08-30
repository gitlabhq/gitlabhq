(function() {
  $.fn.extend({
    disable: function() {
      return $(this).attr('disabled', 'disabled').addClass('disabled');
    }
  });

  $.fn.extend({
    enable: function() {
      return $(this).removeAttr('disabled').removeClass('disabled');
    }
  });

}).call(this);
