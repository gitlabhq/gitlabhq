import { __ } from '~/locale';
import {
  WORK_ITEM_TYPE_VALUE_KEY_RESULT,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  WORK_ITEM_TYPE_VALUE_TASK,
} from '~/work_items/constants';

export const STATUS_ALL = 'all';
export const STATUS_CLOSED = 'closed';
export const STATUS_MERGED = 'merged';
export const STATUS_OPEN = 'opened';
export const STATUS_REOPENED = 'reopened';
export const STATUS_LOCKED = 'locked';
export const STATUS_EMPTY = 'empty';
export const STATUS_ACTIVE = 'active';
export const STATUS_EXPIRED = 'expired';
export const STATUS_UPCOMING = 'upcoming';

export const TITLE_LENGTH_MAX = 255;

export const TYPE_ALERT = 'alert';
export const TYPE_EPIC = 'epic';
export const TYPE_INCIDENT = 'incident';
export const TYPE_ISSUE = 'issue';
export const TYPE_MERGE_REQUEST = 'merge_request';
export const TYPE_MILESTONE = 'milestone';
export const TYPE_TEST_CASE = 'test_case';

export const WORKSPACE_GROUP = 'group';
export const WORKSPACE_PROJECT = 'project';

export const issuableStatusText = {
  [STATUS_UPCOMING]: __('Upcoming'),
  [STATUS_ACTIVE]: __('Active'),
  [STATUS_EXPIRED]: __('Expired'),
  [STATUS_CLOSED]: __('Closed'),
  [STATUS_OPEN]: __('Open'),
  [STATUS_REOPENED]: __('Open'),
  [STATUS_MERGED]: __('Merged'),
  [STATUS_LOCKED]: __('Open'),
};

export const issuableTypeText = {
  [TYPE_ISSUE]: __('issue'),
  [TYPE_EPIC]: __('epic'),
  [TYPE_MERGE_REQUEST]: __('merge request'),
  [TYPE_ALERT]: __('alert'),
  [TYPE_INCIDENT]: __('incident'),
  [TYPE_TEST_CASE]: __('test case'),
  [WORK_ITEM_TYPE_VALUE_KEY_RESULT]: __('key result'),
  [WORK_ITEM_TYPE_VALUE_OBJECTIVE]: __('objective'),
  [WORK_ITEM_TYPE_VALUE_TASK]: __('task'),
};

const SHIFT_KEY = 16;
const CTRL_KEY = 17;
const ALT_KEY = 18;
const ESC_KEY = 27;
const LEFT_ARROW_KEY = 37;
const UP_ARROW_KEY = 38;
const RIGHT_ARROW_KEY = 39;
const DOWN_ARROW_KEY = 40;
const WIN_CMD_KEY = 91;
const CONTEXT_MENU_KEY = 93;

export const NON_INPUT_KEY_EVENTS = [
  { keyCode: SHIFT_KEY, label: 'shift' },
  { keyCode: CTRL_KEY, label: 'control' },
  { keyCode: ALT_KEY, label: 'alt' },
  { keyCode: ESC_KEY, label: 'escape' },
  { keyCode: LEFT_ARROW_KEY, label: 'left' },
  { keyCode: UP_ARROW_KEY, label: 'up' },
  { keyCode: RIGHT_ARROW_KEY, label: 'right' },
  { keyCode: DOWN_ARROW_KEY, label: 'down' },
  { keyCode: WIN_CMD_KEY, label: 'Windows/Command' },
  { keyCode: CONTEXT_MENU_KEY, label: 'ContextMenu' },
];

export const NON_INPUT_KEYS = [
  SHIFT_KEY,
  CTRL_KEY,
  ALT_KEY,
  ESC_KEY,
  LEFT_ARROW_KEY,
  UP_ARROW_KEY,
  RIGHT_ARROW_KEY,
  DOWN_ARROW_KEY,
  WIN_CMD_KEY,
  CONTEXT_MENU_KEY,
];
