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
    'An error occurred while updating the notification settings. Please try again.',
  ),
  loadNotificationLevelErrorMessage: __(
    'An error occurred while loading the notification settings. Please try again.',
  ),
  customNotificationsModal: {
    title: __('Custom notification events'),
    bodyTitle: __('Notification events'),
    bodyMessage: __(
      'Custom notification levels are the same as participating levels. With custom notification levels you will also receive notifications for select events. To find out more, check out %{notificationLinkStart} notification emails%{notificationLinkEnd}.',
    ),
  },
  eventNames: {
    change_reviewer_merge_request: s__('NotificationEvent|Change reviewer merge request'),
    close_issue: s__('NotificationEvent|Close issue'),
    close_merge_request: s__('NotificationEvent|Close merge request'),
    failed_pipeline: s__('NotificationEvent|Failed pipeline'),
    fixed_pipeline: s__('NotificationEvent|Fixed pipeline'),
    issue_due: s__('NotificationEvent|Issue due'),
    merge_merge_request: s__('NotificationEvent|Merge merge request'),
    moved_project: s__('NotificationEvent|Moved project'),
    new_epic: s__('NotificationEvent|New epic'),
    new_issue: s__('NotificationEvent|New issue'),
    new_merge_request: s__('NotificationEvent|New merge request'),
    new_note: s__('NotificationEvent|New note'),
    new_release: s__('NotificationEvent|New release'),
    push_to_merge_request: s__('NotificationEvent|Push to merge request'),
    reassign_issue: s__('NotificationEvent|Reassign issue'),
    reassign_merge_request: s__('NotificationEvent|Reassign merge request'),
    reopen_issue: s__('NotificationEvent|Reopen issue'),
    reopen_merge_request: s__('NotificationEvent|Reopen merge request'),
    merge_when_pipeline_succeeds: s__('NotificationEvent|Merge when pipeline succeeds'),
    success_pipeline: s__('NotificationEvent|Successful pipeline'),
  },
};
