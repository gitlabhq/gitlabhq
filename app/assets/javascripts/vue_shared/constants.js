import { __, n__, sprintf } from '~/locale';
import { TYPE_ISSUE, WORKSPACE_PROJECT } from '~/issues/constants';

const INTERVALS = {
  minute: 'minute',
  hour: 'hour',
  day: 'day',
};

export const FILE_SYMLINK_MODE = '120000';

export const SHORT_DATE_FORMAT = 'mmm dd, yyyy';

export const SHORT_DATE_FORMAT_WITH_TIME = 'mmm dd, yyyy HH:MM';

export const ISO_SHORT_FORMAT = 'yyyy-mm-dd';

export const LONG_DATE_FORMAT_WITH_TZ = 'yyyy-mm-dd HH:MM:ss Z';

export const DATE_FORMATS = [
  SHORT_DATE_FORMAT,
  SHORT_DATE_FORMAT_WITH_TIME,
  ISO_SHORT_FORMAT,
  LONG_DATE_FORMAT_WITH_TZ,
];

const getTimeLabel = (days) => n__('1 day', '%d days', days);

/* eslint-disable @gitlab/require-i18n-strings */
export const timeRanges = [
  {
    label: n__('1 minute', '%d minutes', 30),
    shortcut: '30_minutes',
    duration: { seconds: 60 * 30 },
    name: 'thirtyMinutes',
    interval: INTERVALS.minute,
  },
  {
    label: n__('1 hour', '%d hours', 3),
    shortcut: '3_hours',
    duration: { seconds: 60 * 60 * 3 },
    name: 'threeHours',
    interval: INTERVALS.hour,
  },
  {
    label: n__('1 hour', '%d hours', 8),
    shortcut: '8_hours',
    duration: { seconds: 60 * 60 * 8 },
    name: 'eightHours',
    default: true,
    interval: INTERVALS.hour,
  },
  {
    label: getTimeLabel(1),
    shortcut: '1_day',
    duration: { seconds: 60 * 60 * 24 * 1 },
    name: 'oneDay',
    interval: INTERVALS.hour,
  },
  {
    label: getTimeLabel(3),
    shortcut: '3_days',
    duration: { seconds: 60 * 60 * 24 * 3 },
    name: 'threeDays',
    interval: INTERVALS.hour,
  },
  {
    label: getTimeLabel(7),
    shortcut: '7_days',
    duration: { seconds: 60 * 60 * 24 * 7 * 1 },
    name: 'oneWeek',
    interval: INTERVALS.day,
  },
  {
    label: getTimeLabel(30),
    shortcut: '30_days',
    duration: { seconds: 60 * 60 * 24 * 30 },
    name: 'oneMonth',
    interval: INTERVALS.day,
  },
];
/* eslint-enable @gitlab/require-i18n-strings */

export const defaultTimeRange = timeRanges.find((tr) => tr.default);

export const AVATAR_SHAPE_OPTION_CIRCLE = 'circle';
export const AVATAR_SHAPE_OPTION_RECT = 'rect';

export const confidentialityInfoText = (workspaceType, issuableType) =>
  sprintf(
    __(
      'Only %{workspaceType} members with %{permissions} can view or be notified about this %{issuableType}.',
    ),
    {
      workspaceType: workspaceType === WORKSPACE_PROJECT ? __('project') : __('group'),
      issuableType: issuableType.toLowerCase().replaceAll('_', ' '),
      permissions:
        issuableType === TYPE_ISSUE
          ? __('at least the Planner role, the author, and assignees')
          : __('at least the Planner role'),
    },
  );

export const EDITING_MODE_KEY = 'gl-markdown-editor-mode';
export const EDITING_MODE_MARKDOWN_FIELD = 'markdownField';
export const EDITING_MODE_CONTENT_EDITOR = 'contentEditor';

export const CLEAR_AUTOSAVE_ENTRY_EVENT = 'markdown_clear_autosave_entry';
export const CONTENT_EDITOR_READY_EVENT = 'content_editor_ready';
export const CONTENT_EDITOR_PASTE = 'content_editor_paste';
export const MARKDOWN_EDITOR_READY_EVENT = 'markdown_editor_ready';
