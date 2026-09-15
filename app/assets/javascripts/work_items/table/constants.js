import { __ } from '~/locale';
import { METADATA_KEYS } from '../constants';

export const COLUMN_TITLE = 'title';
export const COLUMN_REFERENCE = 'reference';
export const COLUMN_STATUS = 'status';
export const COLUMN_ASSIGNEES = 'assignees';
export const COLUMN_LABELS = 'labels';
export const COLUMN_WEIGHT = 'weight';
export const COLUMN_MILESTONE = 'milestone';
export const COLUMN_ITERATION = 'iteration';
export const COLUMN_START_DATE = 'startDate';
export const COLUMN_DUE_DATE = 'dueDate';
export const COLUMN_HEALTH_STATUS = 'healthStatus';
export const COLUMN_CREATED_AT = 'createdAt';

/**
 * The columns the table renders, in order.
 *
 * `metadataKey` ties a column to the Display settings toggle that hides the same field in the
 * list and board views. `licensedFeature` names the injected flag that says whether the
 * namespace has the field at all, so unavailable columns don't render as empty ones.
 * `widthClass` sets the column width, since the table is laid out with fixed columns and
 * scrolls horizontally rather than squeezing them.
 */
export const TABLE_COLUMNS = [
  {
    key: COLUMN_TITLE,
    label: __('Title'),
    widthClass: 'gl-w-48',
  },
  {
    key: COLUMN_REFERENCE,
    label: __('Reference'),
    widthClass: 'gl-w-26',
  },
  {
    key: COLUMN_STATUS,
    label: __('Status'),
    widthClass: 'gl-w-20',
    metadataKey: METADATA_KEYS.STATUS,
    licensedFeature: 'hasStatusFeature',
  },
  {
    key: COLUMN_ASSIGNEES,
    label: __('Assignees'),
    widthClass: 'gl-w-26',
    metadataKey: METADATA_KEYS.ASSIGNEE,
  },
  {
    key: COLUMN_LABELS,
    label: __('Labels'),
    widthClass: 'gl-w-48',
    metadataKey: METADATA_KEYS.LABELS,
  },
  {
    key: COLUMN_WEIGHT,
    label: __('Weight'),
    widthClass: 'gl-w-15',
    metadataKey: METADATA_KEYS.WEIGHT,
    licensedFeature: 'hasIssueWeightsFeature',
  },
  {
    key: COLUMN_MILESTONE,
    label: __('Milestone'),
    widthClass: 'gl-w-26',
    metadataKey: METADATA_KEYS.MILESTONE,
  },
  {
    key: COLUMN_ITERATION,
    label: __('Iteration'),
    widthClass: 'gl-w-26',
    metadataKey: METADATA_KEYS.ITERATION,
    licensedFeature: 'hasIterationsFeature',
  },
  {
    key: COLUMN_START_DATE,
    label: __('Start date'),
    widthClass: 'gl-w-20',
    metadataKey: METADATA_KEYS.DATES,
  },
  {
    key: COLUMN_DUE_DATE,
    label: __('Due date'),
    widthClass: 'gl-w-20',
    metadataKey: METADATA_KEYS.DATES,
  },
  {
    key: COLUMN_HEALTH_STATUS,
    label: __('Health status'),
    widthClass: 'gl-w-20',
    metadataKey: METADATA_KEYS.HEALTH,
    licensedFeature: 'hasIssuableHealthStatusFeature',
  },
  {
    key: COLUMN_CREATED_AT,
    label: __('Created date'),
    widthClass: 'gl-w-20',
  },
];
