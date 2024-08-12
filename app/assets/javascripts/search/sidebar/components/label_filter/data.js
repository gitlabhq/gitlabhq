import { __ } from '~/locale';

export const FIRST_DROPDOWN_INDEX = 0;

export const SEARCH_BOX_INDEX = 0;

export const SEARCH_INPUT_DESCRIPTION = 'label-search-input-description';

export const SEARCH_RESULTS_DESCRIPTION = 'label-search-results-description';

const header = __('Labels');

const scopes = {
  ISSUES: 'issues',
};

const filterParam = 'labels';

export const labelFilterData = {
  header,
  scopes,
  filterParam,
};
