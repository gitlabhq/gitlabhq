import { isEqual, sortBy } from 'lodash-es';
import { STATUS_OPEN } from '~/issues/constants';
import {
  FILTERED_SEARCH_TERM,
  OPERATOR_IS,
  TOKEN_TYPE_STATE,
} from '~/vue_shared/components/filtered_search_bar/constants';

// Pure comparisons that decide whether the current view diverges from a
// baseline (a saved view's stored config, or the All-items defaults). The
// caller resolves which baseline applies, so these stay route-agnostic.

export const ALL_ITEMS_DEFAULT_FILTER_TOKENS = Object.freeze([
  Object.freeze({
    type: TOKEN_TYPE_STATE,
    value: Object.freeze({
      data: STATUS_OPEN,
      operator: OPERATOR_IS,
    }),
  }),
]);

export const filtersChanged = ({ filterTokens, baselineTokens }) => {
  const filteredTokens = filterTokens
    .filter((token) => (token.type === FILTERED_SEARCH_TERM ? Boolean(token.value?.data) : true))
    .map(({ id, ...rest }) => {
      if (rest.type === FILTERED_SEARCH_TERM) {
        // Normalize the search-term operator so a present-but-undefined
        // operator compares equal to an absent one.
        return { ...rest, value: { ...rest.value, operator: undefined } };
      }
      return rest;
    });

  // Token order is not significant, so sort by type before comparing.
  return !isEqual(sortBy(filteredTokens, ['type']), sortBy(baselineTokens, ['type']));
};

export const sortChanged = ({ sortKey, baselineSortKey }) => sortKey !== baselineSortKey;

export const viewModeChanged = ({ viewMode, baselineViewMode }) => viewMode !== baselineViewMode;

// The display-preference fields that count towards a view diverging from its
// baseline. Selecting them here keeps the comparison robust to any extra keys
// (e.g. viewMode) present on the raw namespace preferences passed in.
const pickTrackedPreferences = (preferences) => ({
  hiddenMetadataKeys: preferences?.hiddenMetadataKeys ?? [],
  collapsedGroups: preferences?.collapsedGroups ?? [],
  visibleGroups: preferences?.visibleGroups ?? null,
});

export const preferencesChanged = ({ currentPreferences, baselinePreferences }) =>
  !isEqual(pickTrackedPreferences(currentPreferences), pickTrackedPreferences(baselinePreferences));
