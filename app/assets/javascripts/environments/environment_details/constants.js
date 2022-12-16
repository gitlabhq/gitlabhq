import { __ } from '~/locale';

export const ENVIRONMENT_DETAILS_PAGE_SIZE = 20;
export const ENVIRONMENT_DETAILS_TABLE_FIELDS = [
  {
    key: 'status',
    label: __('Status'),
    columnClass: 'gl-w-10p',
    tdClass: 'gl-vertical-align-middle!',
  },
  {
    key: 'id',
    label: __('ID'),
    columnClass: 'gl-w-5p',
    tdClass: 'gl-vertical-align-middle!',
  },
  {
    key: 'triggerer',
    label: __('Triggerer'),
    columnClass: 'gl-w-10p',
    tdClass: 'gl-vertical-align-middle!',
  },
  {
    key: 'commit',
    label: __('Commit'),
    columnClass: 'gl-w-20p',
    tdClass: 'gl-vertical-align-middle!',
  },
  {
    key: 'job',
    label: __('Job'),
    columnClass: 'gl-w-20p',
    tdClass: 'gl-vertical-align-middle!',
  },
  {
    key: 'created',
    label: __('Created'),
    columnClass: 'gl-w-10p',
    tdClass: 'gl-vertical-align-middle! gl-white-space-nowrap',
  },
  {
    key: 'deployed',
    label: __('Deployed'),
    columnClass: 'gl-w-10p',
    tdClass: 'gl-vertical-align-middle! gl-white-space-nowrap',
  },
];
