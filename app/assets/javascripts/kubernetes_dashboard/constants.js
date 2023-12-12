import { s__ } from '~/locale';

export const STATUS_RUNNING = 'Running';
export const STATUS_PENDING = 'Pending';
export const STATUS_SUCCEEDED = 'Succeeded';
export const STATUS_FAILED = 'Failed';
export const STATUS_READY = 'Ready';

export const STATUS_LABELS = {
  [STATUS_RUNNING]: s__('KubernetesDashboard|Running'),
  [STATUS_PENDING]: s__('KubernetesDashboard|Pending'),
  [STATUS_SUCCEEDED]: s__('KubernetesDashboard|Succeeded'),
  [STATUS_FAILED]: s__('KubernetesDashboard|Failed'),
  [STATUS_READY]: s__('KubernetesDashboard|Ready'),
};

export const WORKLOAD_STATUS_BADGE_VARIANTS = {
  [STATUS_RUNNING]: 'info',
  [STATUS_PENDING]: 'warning',
  [STATUS_SUCCEEDED]: 'success',
  [STATUS_FAILED]: 'danger',
  [STATUS_READY]: 'success',
};

export const PAGE_SIZE = 20;

export const TABLE_HEADING_CLASSES = 'gl-bg-gray-50! gl-font-weight-bold gl-white-space-nowrap';

export const DEFAULT_WORKLOAD_TABLE_FIELDS = [
  {
    key: 'name',
    label: s__('KubernetesDashboard|Name'),
  },
  {
    key: 'status',
    label: s__('KubernetesDashboard|Status'),
  },
  {
    key: 'namespace',
    label: s__('KubernetesDashboard|Namespace'),
  },
  {
    key: 'age',
    label: s__('KubernetesDashboard|Age'),
  },
];

export const STATUS_TRUE = 'True';
export const STATUS_FALSE = 'False';
