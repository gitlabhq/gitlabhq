/* eslint-disable func-names, space-before-function-paren, object-shorthand, comma-dangle, padded-blocks, max-len */
// Disable an element and add the 'disabled' Bootstrap class
(function() {
  $.fn.extend({
    disable: function() {
      return $(this).attr('disabled', 'disabled').addClass('disabled');
    }
  });

  // Enable an element and remove the 'disabled' Bootstrap class
  $.fn.extend({
    enable: function() {
      return $(this).removeAttr('disabled').removeClass('disabled');
    }
  });

}).call(this);
