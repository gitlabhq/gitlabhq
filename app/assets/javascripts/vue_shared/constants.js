import { __ } from '~/locale';

const INTERVALS = {
  minute: 'minute',
  hour: 'hour',
  day: 'day',
};

export const FILE_SYMLINK_MODE = '120000';

export const SHORT_DATE_FORMAT = 'd mmm, yyyy';

export const timeRanges = [
  {
    label: __('30 minutes'),
    duration: { seconds: 60 * 30 },
    name: 'thirtyMinutes',
    interval: INTERVALS.minute,
  },
  {
    label: __('3 hours'),
    duration: { seconds: 60 * 60 * 3 },
    name: 'threeHours',
    interval: INTERVALS.hour,
  },
  {
    label: __('8 hours'),
    duration: { seconds: 60 * 60 * 8 },
    name: 'eightHours',
    default: true,
    interval: INTERVALS.hour,
  },
  {
    label: __('1 day'),
    duration: { seconds: 60 * 60 * 24 * 1 },
    name: 'oneDay',
    interval: INTERVALS.hour,
  },
  {
    label: __('3 days'),
    duration: { seconds: 60 * 60 * 24 * 3 },
    name: 'threeDays',
    interval: INTERVALS.hour,
  },
  {
    label: __('7 days'),
    duration: { seconds: 60 * 60 * 24 * 7 * 1 },
    name: 'oneWeek',
    interval: INTERVALS.day,
  },
  {
    label: __('30 days'),
    duration: { seconds: 60 * 60 * 24 * 30 },
    name: 'oneMonth',
    interval: INTERVALS.day,
  },
];

export const defaultTimeRange = timeRanges.find((tr) => tr.default);
export const getTimeWindow = (timeWindowName) =>
  timeRanges.find((tr) => tr.name === timeWindowName);
