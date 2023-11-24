import { s__ } from '~/locale';

export const PHASE_RUNNING = 'Running';
export const PHASE_PENDING = 'Pending';
export const PHASE_SUCCEEDED = 'Succeeded';
export const PHASE_FAILED = 'Failed';

export const STATUS_LABELS = {
  [PHASE_RUNNING]: s__('KubernetesDashboard|Running'),
  [PHASE_PENDING]: s__('KubernetesDashboard|Pending'),
  [PHASE_SUCCEEDED]: s__('KubernetesDashboard|Succeeded'),
  [PHASE_FAILED]: s__('KubernetesDashboard|Failed'),
};

export const WORKLOAD_STATUS_BADGE_VARIANTS = {
  [PHASE_RUNNING]: 'info',
  [PHASE_PENDING]: 'warning',
  [PHASE_SUCCEEDED]: 'success',
  [PHASE_FAILED]: 'danger',
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
