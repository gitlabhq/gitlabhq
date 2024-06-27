import {
  SORT_DIRECTION_ASC,
  SORT_DIRECTION_DESC,
  SORT_ITEM_NAME,
} from '~/organizations/shared/constants';
import { SORT_ITEMS_GRAPHQL_ENUMS } from './constants';

export const userPreferenceSortName = (userPreferenceSort) => {
  if (!userPreferenceSort) {
    return SORT_ITEM_NAME.value;
  }

  const userPreferenceSortNameGraphQLEnum = userPreferenceSort
    .replace(`_${SORT_DIRECTION_ASC}`, '')
    .replace(`_${SORT_DIRECTION_DESC}`, '')
    .toUpperCase();

  return (
    Object.entries(SORT_ITEMS_GRAPHQL_ENUMS).find(
      ([, sortNameGraphQLEnum]) => sortNameGraphQLEnum === userPreferenceSortNameGraphQLEnum,
    )?.[0] || SORT_ITEM_NAME.value
  );
};

export const userPreferenceSortDirection = (userPreferenceSort) => {
  return userPreferenceSort?.endsWith(SORT_DIRECTION_DESC)
    ? SORT_DIRECTION_DESC
    : SORT_DIRECTION_ASC;
};
