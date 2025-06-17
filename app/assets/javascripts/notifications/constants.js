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
    participating: __('You will only receive notifications for items you have participated in'),
    mention: __('You will receive notifications only for comments in which you were @mentioned'),
    watch: __('You will receive notifications for most activity'),
    disabled: __('You will not get any notifications via email'),
    global: __('Use your global notification setting'),
    custom: __(
      'You will only receive notifications for items you have participated in and the events you choose',
    ),
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
      'With custom notification levels you receive notifications for the same events as in the Participate level, with additional selected events. For more information, see %{notificationLinkStart}notification emails%{notificationLinkEnd}.',
    ),
  },
  eventNames: {
    approver: s__("NotificationEvent|Merge request you're eligible to approve is created"),
    change_reviewer_merge_request: s__('NotificationEvent|Merge request reviewers are changed'),
    close_issue: s__('NotificationEvent|Issue is closed'),
    close_merge_request: s__('NotificationEvent|Merge request is closed'),
    failed_pipeline: s__('NotificationEvent|Pipeline fails'),
    fixed_pipeline: s__('NotificationEvent|Pipeline is fixed'),
    issue_due: s__('NotificationEvent|Issue is due tomorrow'),
    merge_merge_request: s__('NotificationEvent|Merge request is merged'),
    merge_when_pipeline_succeeds: s__('NotificationEvent|Merge request is set to auto-merge'),
    moved_project: s__('NotificationEvent|Project is moved'),
    new_epic: s__('NotificationEvent|Epic is created'),
    new_issue: s__('NotificationEvent|Issue is created'),
    new_merge_request: s__('NotificationEvent|Merge request is created'),
    new_note: s__('NotificationEvent|Comment is added'),
    new_release: s__('NotificationEvent|Release is created'),
    push_to_merge_request: s__('NotificationEvent|Merge request receives a push'),
    reassign_issue: s__('NotificationEvent|Issue is reassigned'),
    reassign_merge_request: s__('NotificationEvent|Merge request is reassigned'),
    reopen_issue: s__('NotificationEvent|Issue is reopened'),
    reopen_merge_request: s__('NotificationEvent|Merge request is reopened'),
    service_account_failed_pipeline: s__('NotificationEvent|Pipeline by Service Account fails'),
    service_account_fixed_pipeline: s__('NotificationEvent|Pipeline by Service Account is fixed'),
    service_account_success_pipeline: s__(
      'NotificationEvent|Pipeline by Service Account is successful',
    ),
    success_pipeline: s__('NotificationEvent|Pipeline is successful'),
  },
};
