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
