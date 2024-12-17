import { __, s__ } from '~/locale';

export const STATUS_RUNNING = 'Running';
export const STATUS_PENDING = 'Pending';
export const STATUS_SUCCEEDED = 'Succeeded';
export const STATUS_FAILED = 'Failed';
export const STATUS_READY = 'Ready';
export const STATUS_COMPLETED = 'Completed';
export const STATUS_SUSPENDED = 'Suspended';
export const STATUS_RECONCILED = 'reconciled';
export const STATUS_RECONCILING = 'reconciling';
export const STATUS_STALLED = 'stalled';
export const STATUS_UNKNOWN = 'unknown';
export const STATUS_UNAVAILABLE = 'unavailable';

export const STATUS_LABELS = {
  [STATUS_RUNNING]: s__('KubernetesDashboard|Running'),
  [STATUS_PENDING]: s__('KubernetesDashboard|Pending'),
  [STATUS_SUCCEEDED]: s__('KubernetesDashboard|Succeeded'),
  [STATUS_FAILED]: s__('KubernetesDashboard|Failed'),
  [STATUS_READY]: s__('KubernetesDashboard|Ready'),
  [STATUS_COMPLETED]: s__('KubernetesDashboard|Completed'),
  [STATUS_SUSPENDED]: s__('KubernetesDashboard|Suspended'),
  [STATUS_RECONCILED]: s__('Environment|Reconciled'),
  [STATUS_RECONCILING]: s__('Environment|Reconciling'),
  [STATUS_STALLED]: s__('Environment|Stalled'),
  [STATUS_UNKNOWN]: s__('Environment|Unknown'),
  [STATUS_UNAVAILABLE]: s__('Environment|Unavailable'),
  failed: s__('KubernetesDashboard|Failed'),
};

export const WORKLOAD_STATUS_BADGE_VARIANTS = {
  [STATUS_RUNNING]: 'info',
  [STATUS_PENDING]: 'warning',
  [STATUS_SUCCEEDED]: 'success',
  [STATUS_FAILED]: 'danger',
  [STATUS_READY]: 'success',
  [STATUS_COMPLETED]: 'success',
  [STATUS_SUSPENDED]: 'neutral',
  [STATUS_RECONCILED]: 'success',
  [STATUS_RECONCILING]: 'info',
  [STATUS_STALLED]: 'warning',
  [STATUS_UNKNOWN]: 'neutral',
  [STATUS_UNAVAILABLE]: 'neutral',
  failed: 'danger',
};

export const PAGE_SIZE = 20;

export const DEFAULT_WORKLOAD_TABLE_FIELDS = [
  {
    key: 'name',
    label: s__('KubernetesDashboard|Name'),
    tdClass: 'md:gl-w-1/2 lg:gl-w-4/10 gl-break-anywhere',
  },
  {
    key: 'status',
    label: s__('KubernetesDashboard|Status'),
    tdClass: 'md:gl-w-15',
  },
  {
    key: 'namespace',
    label: s__('KubernetesDashboard|Namespace'),
    tdClass: 'gl-md-w-30p lg:gl-w-4/10 gl-break-anywhere',
  },
  {
    key: 'age',
    label: s__('KubernetesDashboard|Age'),
  },
];

export const PODS_TABLE_FIELDS = [
  {
    key: 'name',
    label: s__('KubernetesDashboard|Name'),
    tdClass: 'md:gl-w-1/4 gl-break-anywhere',
  },
  {
    key: 'status',
    label: s__('KubernetesDashboard|Status'),
    tdClass: 'md:gl-w-1/6',
  },
  {
    key: 'namespace',
    label: s__('KubernetesDashboard|Namespace'),
    tdClass: 'md:gl-w-1/4 gl-break-anywhere',
  },
  {
    key: 'age',
    label: s__('KubernetesDashboard|Age'),
  },
  {
    key: 'logs',
    label: s__('KubernetesDashboard|Logs'),
    sortable: false,
  },
  {
    key: 'actions',
    label: '',
    sortable: false,
  },
];

export const STATUS_TRUE = 'True';
export const STATUS_FALSE = 'False';

export const SERVICES_TABLE_FIELDS = [
  {
    key: 'name',
    label: __('Name'),
  },
  {
    key: 'namespace',
    label: __('Namespace'),
  },
  {
    key: 'type',
    label: __('Type'),
  },
  {
    key: 'clusterIP',
    label: s__('Environment|Cluster IP'),
  },
  {
    key: 'externalIP',
    label: s__('Environment|External IP'),
  },
  {
    key: 'ports',
    label: s__('Environment|Ports'),
  },
  {
    key: 'age',
    label: s__('Environment|Age'),
  },
];

export const WORKLOAD_DETAILS_SECTIONS = {
  STATUS: 'status',
};
