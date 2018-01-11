import _ from 'underscore';

export default function initBroadcastMessagesForm() {
  $('input#broadcast_message_color').on('input', function onMessageColorInput() {
    const previewColor = $(this).val();
    $('div.broadcast-message-preview').css('background-color', previewColor);
  });

  $('input#broadcast_message_font').on('input', function onMessageFontInput() {
    const previewColor = $(this).val();
    $('div.broadcast-message-preview').css('color', previewColor);
  });

  const previewPath = $('textarea#broadcast_message_message').data('preview-path');

  $('textarea#broadcast_message_message').on('input', _.debounce(function onMessageInput() {
    const message = $(this).val();
    if (message === '') {
      $('.js-broadcast-message-preview').text('Your message here');
    } else {
      $.ajax({
        url: previewPath,
        type: 'POST',
        data: {
          broadcast_message: { message },
        },
      });
    }
  }, 250));
}
