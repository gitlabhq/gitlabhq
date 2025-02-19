import { s__ } from '~/locale';

export const BASE_IMPORT_TABLE_ROW_GRID_CLASSES = 'gl-grid-cols-[repeat(2,1fr),200px,200px]';

export const SOURCE_TYPE_GROUP = 'group';
export const SOURCE_TYPE_PROJECT = 'project';
export const SOURCE_TYPE_FILE = 'file';

export const IMPORT_HISTORY_TABLE_STATUS = {
  inProgress: 'started',
  complete: 'finished',
  failed: 'failed',
  timeout: 'timeout',
  unstarted: 'created',
};

export const IMPORT_HISTORY_TABLE_STATUS_DATA = {
  [IMPORT_HISTORY_TABLE_STATUS.unstarted]: {
    label: s__('Import|Not started'),
    variant: 'neutral',
    icon: 'status-waiting',
  },
  [IMPORT_HISTORY_TABLE_STATUS.inProgress]: {
    label: s__('Import|In progress'),
    variant: 'warning',
    icon: 'status-running',
  },
  [IMPORT_HISTORY_TABLE_STATUS.complete]: {
    label: s__('Import|Complete'),
    variant: 'success',
    icon: 'status-success',
  },
  [IMPORT_HISTORY_TABLE_STATUS.failed]: {
    label: s__('Import|Failed'),
    variant: 'danger',
    icon: 'status-failed',
  },
  [IMPORT_HISTORY_TABLE_STATUS.timeout]: {
    label: s__('Import|Failed'),
    variant: 'danger',
    icon: 'status-failed',
  },
};
