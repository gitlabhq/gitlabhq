import { s__ } from '~/locale';

export const DEFAULT_DAYS_IN_PAST = 30;
export const DEFAULT_DAYS_TO_DISPLAY = 30;
export const OVERVIEW_STAGE_ID = 'overview';

export const DEFAULT_VALUE_STREAM = {
  id: 'default',
  slug: 'default',
  name: 'default',
};

export const NOT_ENOUGH_DATA_ERROR = s__(
  "ValueStreamAnalyticsStage|We don't have enough data to show this stage.",
);

export const PAGINATION_TYPE = 'keyset';
export const PAGINATION_SORT_FIELD_END_EVENT = 'end_event';
export const PAGINATION_SORT_FIELD_DURATION = 'duration';
export const PAGINATION_SORT_DIRECTION_DESC = 'desc';
export const PAGINATION_SORT_DIRECTION_ASC = 'asc';

export const STAGE_TITLE_STAGING = 'staging';
export const STAGE_TITLE_TEST = 'test';
