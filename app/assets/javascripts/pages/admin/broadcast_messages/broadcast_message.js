import $ from 'jquery';
import { debounce } from 'lodash';
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __ } from '~/locale';

export default () => {
  const $broadcastMessageTheme = $('.js-broadcast-message-theme');
  const $broadcastMessageType = $('.js-broadcast-message-type');
  const $broadcastBannerMessagePreview = $('.js-broadcast-banner-message-preview [role="alert"]');
  const $broadcastMessage = $('.js-broadcast-message-message');
  const $jsBroadcastMessagePreview = $('#broadcast-message-preview');

  const reloadPreview = function reloadPreview() {
    const previewPath = $broadcastMessage.data('previewPath');
    const message = $broadcastMessage.val();
    const type = $broadcastMessageType.val();
    const theme = $broadcastMessageTheme.val();

    axios
      .post(previewPath, {
        broadcast_message: {
          message,
          broadcast_type: type,
          theme,
        },
      })
      .then(({ data }) => {
        $jsBroadcastMessagePreview.html(data);
      })
      .catch(() =>
        createAlert({
          message: __('An error occurred while rendering preview broadcast message'),
        }),
      );
  };

  $broadcastMessageTheme.on('change', reloadPreview);

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
};
