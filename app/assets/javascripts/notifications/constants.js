import { __, s__ } from '~/locale';

export const CUSTOM_LEVEL = 'custom';

export const i18n = {
  notificationTitles: {
    participating: s__('NotificationLevel|Participate'),
    mention: s__('NotificationLevel|On mention'),
    watch: s__('NotificationLevel|Watch'),
    global: s__('NotificationLevel|Global'),
    disabled: s__('NotificationLevel|Disabled'),
    custom: s__('NotificationLevel|Custom'),
  },
  notificationTooltipTitle: __('Notification setting - %{notification_title}'),
  notificationDescriptions: {
    participating: __('You will only receive notifications for threads you have participated in'),
    mention: __('You will receive notifications only for comments in which you were @mentioned'),
    watch: __('You will receive notifications for any activity'),
    disabled: __('You will not get any notifications via email'),
    global: __('Use your global notification setting'),
    custom: __('You will only receive notifications for the events you choose'),
    owner_disabled: __('Notifications have been disabled by the project or group owner'),
  },
  updateNotificationLevelErrorMessage: __(
    'An error occured while updating the notification settings. Please try again.',
  ),
};
