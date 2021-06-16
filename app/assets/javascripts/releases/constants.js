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

export const ASCENDING_ORDER = 'asc';
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

export const RELEASED_AT_ASC = 'RELEASED_AT_ASC';
export const RELEASED_AT_DESC = 'RELEASED_AT_DESC';
export const CREATED_ASC = 'CREATED_ASC';
export const CREATED_DESC = 'CREATED_DESC';
export const ALL_SORTS = [RELEASED_AT_ASC, RELEASED_AT_DESC, CREATED_ASC, CREATED_DESC];

export const SORT_MAP = {
  [RELEASED_AT]: {
    [ASCENDING_ORDER]: RELEASED_AT_ASC,
    [DESCENDING_ORDER]: RELEASED_AT_DESC,
  },
  [CREATED_AT]: {
    [ASCENDING_ORDER]: CREATED_ASC,
    [DESCENDING_ORDER]: CREATED_DESC,
  },
};

export const DEFAULT_SORT = RELEASED_AT_DESC;
