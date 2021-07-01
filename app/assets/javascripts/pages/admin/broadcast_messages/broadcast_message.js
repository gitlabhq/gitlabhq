import $ from 'jquery';
import { debounce } from 'lodash';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { textColorForBackground } from '~/lib/utils/color_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __ } from '~/locale';

export default () => {
  const $broadcastMessageColor = $('.js-broadcast-message-color');
  const $broadcastMessageType = $('.js-broadcast-message-type');
  const $broadcastBannerMessagePreview = $('.js-broadcast-banner-message-preview');
  const $broadcastMessage = $('.js-broadcast-message-message');
  const $jsBroadcastMessagePreview = $('.js-broadcast-message-preview');

  const reloadPreview = function reloadPreview() {
    const previewPath = $broadcastMessage.data('previewPath');
    const message = $broadcastMessage.val();
    const type = $broadcastMessageType.val();

    if (message === '') {
      $jsBroadcastMessagePreview.text(__('Your message here'));
    } else {
      axios
        .post(previewPath, {
          broadcast_message: {
            message,
            broadcast_type: type,
          },
        })
        .then(({ data }) => {
          $jsBroadcastMessagePreview.html(data.message);
        })
        .catch(() =>
          createFlash({
            message: __('An error occurred while rendering preview broadcast message'),
          }),
        );
    }
  };

  $broadcastMessageColor.on('input', function onMessageColorInput() {
    const previewColor = $(this).val();
    $broadcastBannerMessagePreview.css('background-color', previewColor);
  });

  $('input#broadcast_message_font').on('input', function onMessageFontInput() {
    const previewColor = $(this).val();
    $broadcastBannerMessagePreview.css('color', previewColor);
  });

  $broadcastMessageType.on('change', () => {
    const $broadcastMessageColorFormGroup = $('.js-broadcast-message-background-color-form-group');
    const $broadcastMessageDismissableFormGroup = $('.js-broadcast-message-dismissable-form-group');
    const $broadcastNotificationMessagePreview = $('.js-broadcast-notification-message-preview');

    $broadcastMessageColorFormGroup.toggleClass('hidden');
    $broadcastMessageDismissableFormGroup.toggleClass('hidden');
    $broadcastBannerMessagePreview.toggleClass('hidden');
    $broadcastNotificationMessagePreview.toggleClass('hidden');

    reloadPreview();
  });

  $broadcastMessage.on(
    'input',
    debounce(() => {
      reloadPreview();
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
  );

  const updateColorPreview = () => {
    const selectedBackgroundColor = $broadcastMessageColor.val();
    const contrastTextColor = textColorForBackground(selectedBackgroundColor);

    // save contrastTextColor to hidden input field
    $('input.text-font-color').val(contrastTextColor);

    // Updates the preview color with the hex-color input
    const selectedColorStyle = {
      backgroundColor: selectedBackgroundColor,
      color: contrastTextColor,
    };

    $('.label-color-preview').css(selectedColorStyle);

    return $jsBroadcastMessagePreview.css(selectedColorStyle);
  };

  const setSuggestedColor = (e) => {
    const color = $(e.currentTarget).data('color');
    $broadcastMessageColor
      .val(color)
      // Notify the form, that color has changed
      .trigger('input');
    // Only banner supports colors
    if ($broadcastMessageType === 'banner') {
      updateColorPreview();
    }
    return e.preventDefault();
  };

  $(document).on('click', '.suggest-colors a', setSuggestedColor);
};
