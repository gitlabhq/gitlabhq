import { __ } from '~/locale';

export const sidebarAnimationDuration = 300; // milliseconds.

export const chartHeight = 300;

export const graphTypes = {
  deploymentData: 'scatter',
};

export const lineTypes = {
  default: 'solid',
};

export const timeWindows = {
  thirtyMinutes: __('30 minutes'),
  threeHours: __('3 hours'),
  eightHours: __('8 hours'),
  oneDay: __('1 day'),
  threeDays: __('3 days'),
  oneWeek: __('1 week'),
};

export const timeWindowsKeyNames = {
  thirtyMinutes: 'thirtyMinutes',
  threeHours: 'threeHours',
  eightHours: 'eightHours',
  oneDay: 'oneDay',
  threeDays: 'threeDays',
  oneWeek: 'oneWeek',
};
