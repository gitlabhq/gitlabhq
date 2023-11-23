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
