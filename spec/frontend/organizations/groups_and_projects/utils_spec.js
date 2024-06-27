import {
  SORT_ITEM_NAME,
  SORT_ITEM_CREATED_AT,
  SORT_ITEM_UPDATED_AT,
  SORT_DIRECTION_DESC,
  SORT_DIRECTION_ASC,
} from '~/organizations/shared/constants';
import {
  userPreferenceSortName,
  userPreferenceSortDirection,
} from '~/organizations/groups_and_projects/utils';

describe('userPreferenceSortName', () => {
  it.each`
    userPreferenceSort    | expected
    ${null}               | ${SORT_ITEM_NAME.value}
    ${'unsupported_sort'} | ${SORT_ITEM_NAME.value}
    ${'name_asc'}         | ${SORT_ITEM_NAME.value}
    ${'name_desc'}        | ${SORT_ITEM_NAME.value}
    ${'created_asc'}      | ${SORT_ITEM_CREATED_AT.value}
    ${'created_desc'}     | ${SORT_ITEM_CREATED_AT.value}
    ${'updated_asc'}      | ${SORT_ITEM_UPDATED_AT.value}
    ${'updated_desc'}     | ${SORT_ITEM_UPDATED_AT.value}
  `(
    'returns $expected when userPreferenceSort argument is $userPreferenceSort',
    ({ userPreferenceSort, expected }) => {
      expect(userPreferenceSortName(userPreferenceSort)).toBe(expected);
    },
  );
});

describe('userPreferenceSortDirection', () => {
  it.each`
    userPreferenceSort    | expected
    ${null}               | ${SORT_DIRECTION_ASC}
    ${'unsupported_sort'} | ${SORT_DIRECTION_ASC}
    ${'name_asc'}         | ${SORT_DIRECTION_ASC}
    ${'name_desc'}        | ${SORT_DIRECTION_DESC}
  `(
    'returns $expected when userPreferenceSort argument is $userPreferenceSort',
    ({ userPreferenceSort, expected }) => {
      expect(userPreferenceSortDirection(userPreferenceSort)).toBe(expected);
    },
  );
});
