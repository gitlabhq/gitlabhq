/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, no-var, quotes, no-else-return, object-shorthand, comma-dangle, padded-blocks, max-len */
(function() {
  $(function() {
    var previewPath;
    $('input#broadcast_message_color').on('input', function() {
      var previewColor;
      previewColor = $(this).val();
      return $('div.broadcast-message-preview').css('background-color', previewColor);
    });
    $('input#broadcast_message_font').on('input', function() {
      var previewColor;
      previewColor = $(this).val();
      return $('div.broadcast-message-preview').css('color', previewColor);
    });
    previewPath = $('textarea#broadcast_message_message').data('preview-path');
    return $('textarea#broadcast_message_message').on('input', function() {
      var message;
      message = $(this).val();
      if (message === '') {
        return $('.js-broadcast-message-preview').text("Your message here");
      } else {
        return $.ajax({
          url: previewPath,
          type: "POST",
          data: {
            broadcast_message: {
              message: message
            }
          }
        });
      }
    });
  });

}).call(this);
