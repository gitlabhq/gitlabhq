import { s__ } from '~/locale';

export const TYPE_BANNER = 'banner';
export const TYPE_NOTIFICATION = 'notification';

export const TYPES = [
  { value: TYPE_BANNER, text: s__('BroadcastMessages|Banner') },
  { value: TYPE_NOTIFICATION, text: s__('BroadcastMessages|Notification') },
];

export const THEMES = [
  { value: 'indigo', text: s__('BroadcastMessages|Indigo') },
  { value: 'light-indigo', text: s__('BroadcastMessages|Light Indigo') },
  { value: 'blue', text: s__('BroadcastMessages|Blue') },
  { value: 'light-blue', text: s__('BroadcastMessages|Light Blue') },
  { value: 'green', text: s__('BroadcastMessages|Green') },
  { value: 'light-green', text: s__('BroadcastMessages|Light Green') },
  { value: 'red', text: s__('BroadcastMessages|Red') },
  { value: 'light-red', text: s__('BroadcastMessages|Light Red') },
  { value: 'dark', text: s__('BroadcastMessages|Dark') },
  { value: 'light', text: s__('BroadcastMessages|Light') },
];

export const NEW_BROADCAST_MESSAGE = {
  message: '',
  broadcastType: TYPES[0].value,
  theme: THEMES[0].value,
  dismissable: false,
  targetPath: '',
  targetAccessLevels: [],
  startsAt: new Date(),
  endsAt: new Date(),
};
