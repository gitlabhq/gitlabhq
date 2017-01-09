/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, no-var, quotes, no-else-return, object-shorthand, comma-dangle, padded-blocks, max-len */
(function() {
  $(function() {
    var previewPath;
    $('input#broadcast_message_color').off('input.messageColor').on('input.messageColor', function() {
      var previewColor;
      previewColor = $(this).val();
      return $('div.broadcast-message-preview').css('background-color', previewColor);
    });
    $('input#broadcast_message_font').off('input.messageFont').on('input.messageFont', function() {
      var previewColor;
      previewColor = $(this).val();
      return $('div.broadcast-message-preview').css('color', previewColor);
    });
    previewPath = $('textarea#broadcast_message_message').data('preview-path');
    return $('textarea#broadcast_message_message').off('input.messageText').on('input.messageText', function() {
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
