import { __, s__ } from '~/locale';

export const OVERVIEW_STAGE_ID = 'overview';

export const DEFAULT_VALUE_STREAM = {
  id: 'default',
  slug: 'default',
  name: 'default',
};

export const NOT_ENOUGH_DATA_ERROR = s__(
  'ValueStreamAnalyticsStage|There are 0 items to show in this stage, for these filters, within this time range.',
);

export const PAGINATION_TYPE = 'keyset';
export const PAGINATION_SORT_FIELD_END_EVENT = 'end_event';
export const PAGINATION_SORT_FIELD_DURATION = 'duration';
export const PAGINATION_SORT_DIRECTION_DESC = 'desc';
export const PAGINATION_SORT_DIRECTION_ASC = 'asc';
export const FIELD_KEY_TITLE = 'title';

export const I18N_VSA_ERROR_STAGES = __(
  'There was an error fetching value stream analytics stages.',
);
export const I18N_VSA_ERROR_STAGE_MEDIAN = __('There was an error fetching median data for stages');
export const I18N_VSA_ERROR_SELECTED_STAGE = __(
  'There was an error fetching data for the selected stage',
);

export const MILESTONES_ENDPOINT = '/-/milestones.json';
export const LABELS_ENDPOINT = '/-/labels.json';
export const MAX_LABELS = 100;
