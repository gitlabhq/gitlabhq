import $ from 'jquery';
import _ from 'underscore';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import { __ } from '~/locale';

export default () => {
  $('input#broadcast_message_color').on('input', function onMessageColorInput() {
    const previewColor = $(this).val();
    $('div.broadcast-message-preview').css('background-color', previewColor);
  });

  $('input#broadcast_message_font').on('input', function onMessageFontInput() {
    const previewColor = $(this).val();
    $('div.broadcast-message-preview').css('color', previewColor);
  });

  const previewPath = $('textarea#broadcast_message_message').data('previewPath');

  $('textarea#broadcast_message_message').on('input', _.debounce(function onMessageInput() {
    const message = $(this).val();
    if (message === '') {
      $('.js-broadcast-message-preview').text('Your message here');
    } else {
      axios.post(previewPath, {
        broadcast_message: {
          message,
        },
      })
      .then(({ data }) => {
        $('.js-broadcast-message-preview').html(data.message);
      })
      .catch(() => flash(__('An error occurred while rendering preview broadcast message')));
    }
  }, 250));
};
