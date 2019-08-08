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

export const secondsIn = {
  thirtyMinutes: 60 * 30,
  threeHours: 60 * 60 * 3,
  eightHours: 60 * 60 * 8,
  oneDay: 60 * 60 * 24 * 1,
  threeDays: 60 * 60 * 24 * 3,
  oneWeek: 60 * 60 * 24 * 7 * 1,
};

export const timeWindowsKeyNames = Object.keys(secondsIn).reduce(
  (otherTimeWindows, timeWindow) => ({
    ...otherTimeWindows,
    [timeWindow]: timeWindow,
  }),
  {},
);
