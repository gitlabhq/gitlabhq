import { __ } from '~/locale';

export const MAX_MILESTONES_TO_DISPLAY = 5;

export const BACK_URL_PARAM = 'back_url';

export const ASSET_LINK_TYPE = Object.freeze({
  OTHER: 'other',
  IMAGE: 'image',
  PACKAGE: 'package',
  RUNBOOK: 'runbook',
});

export const DEFAULT_ASSET_LINK_TYPE = ASSET_LINK_TYPE.OTHER;

export const PAGE_SIZE = 10;

export const ASCENDING_ODER = 'asc';
export const DESCENDING_ORDER = 'desc';
export const RELEASED_AT = 'released_at';
export const CREATED_AT = 'created_at';

export const SORT_OPTIONS = [
  {
    orderBy: RELEASED_AT,
    label: __('Released date'),
  },
  {
    orderBy: CREATED_AT,
    label: __('Created date'),
  },
];
