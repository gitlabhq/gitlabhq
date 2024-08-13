import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import {
  apiParams,
  apiParamsWithWildcardValues,
  filteredTokens,
  filteredTokensWithWildcardValues,
  groupedFilteredTokens,
  locationSearch,
  locationSearchWithWildcardValues,
  urlParams,
  urlParamsWithWildcardValues,
} from 'jest/issues/list/mock_data';
import { STATUS_CLOSED } from '~/issues/constants';
import { CREATED_DESC, UPDATED_DESC, urlSortParams } from '~/issues/list/constants';
import {
  convertToApiParams,
  convertToSearchQuery,
  convertToUrlParams,
  deriveSortKey,
  getDefaultWorkItemTypes,
  getFilterTokens,
  getInitialPageParams,
  getSortOptions,
  getTypeTokenOptions,
  groupMultiSelectFilterTokens,
} from '~/issues/list/utils';
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import {
  WORK_ITEM_TYPE_ENUM_INCIDENT,
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_ENUM_TASK,
} from '~/work_items/constants';

describe('getDefaultWorkItemTypes', () => {
  it('returns default work item types', () => {
    const types = getDefaultWorkItemTypes({
      hasEpicsFeature: true,
      hasOkrsFeature: true,
      hasQualityManagementFeature: true,
    });

    expect(types).toEqual([
      WORK_ITEM_TYPE_ENUM_ISSUE,
      WORK_ITEM_TYPE_ENUM_INCIDENT,
      WORK_ITEM_TYPE_ENUM_TASK,
    ]);
  });
});

describe('getTypeTokenOptions', () => {
  it('returns options for the Type token', () => {
    const options = getTypeTokenOptions({
      hasEpicsFeature: true,
      hasOkrsFeature: true,
      hasQualityManagementFeature: true,
    });

    expect(options).toEqual([
      { icon: 'issue-type-issue', title: 'Issue', value: 'issue' },
      { icon: 'issue-type-incident', title: 'Incident', value: 'incident' },
      { icon: 'issue-type-task', title: 'Task', value: 'task' },
    ]);
  });
});

describe('getInitialPageParams', () => {
  it('returns page params with a default page size when no arguments are given', () => {
    expect(getInitialPageParams()).toEqual({ firstPageSize: DEFAULT_PAGE_SIZE });
  });

  it('returns page params with the given page size', () => {
    const pageSize = 100;
    expect(getInitialPageParams(pageSize)).toEqual({ firstPageSize: pageSize });
  });

  it('does not return firstPageSize when lastPageSize is provided', () => {
    const firstPageSize = 100;
    const lastPageSize = 50;
    const afterCursor = undefined;
    const beforeCursor = 'randomCursorString';
    const pageParams = getInitialPageParams(
      100,
      firstPageSize,
      lastPageSize,
      afterCursor,
      beforeCursor,
    );

    expect(pageParams).toEqual({ lastPageSize, beforeCursor });
  });
});

describe('deriveSortKey', () => {
  describe('when given a legacy sort', () => {
    it.each(Object.keys(urlSortParams))('returns the equivalent GraphQL sort enum', (sort) => {
      const legacySort = urlSortParams[sort];
      expect(deriveSortKey({ sort: legacySort })).toBe(sort);
    });
  });

  describe('when given a GraphQL sort enum', () => {
    it.each(Object.keys(urlSortParams))('returns a GraphQL sort enum', (sort) => {
      expect(deriveSortKey({ sort })).toBe(sort);
    });
  });

  describe('when given neither a legacy sort nor a GraphQL sort enum', () => {
    it.each(['', 'asdf', null, undefined])('returns CREATED_DESC by default', (sort) => {
      expect(deriveSortKey({ sort })).toBe(CREATED_DESC);
    });

    it.each(['', 'asdf', null, undefined])(
      'returns UPDATED_DESC when state=STATUS_CLOSED',
      (sort) => {
        expect(deriveSortKey({ sort, state: STATUS_CLOSED })).toBe(UPDATED_DESC);
      },
    );
  });
});

describe('getSortOptions', () => {
  describe.each`
    hasIssuableHealthStatusFeature | hasIssueWeightsFeature | hasBlockedIssuesFeature | length | containsHealthStatus | containsWeight | containsBlocking
    ${false}                       | ${false}               | ${false}                | ${10}  | ${false}             | ${false}       | ${false}
    ${false}                       | ${false}               | ${true}                 | ${11}  | ${false}             | ${false}       | ${true}
    ${false}                       | ${true}                | ${false}                | ${11}  | ${false}             | ${true}        | ${false}
    ${false}                       | ${true}                | ${true}                 | ${12}  | ${false}             | ${true}        | ${true}
    ${true}                        | ${false}               | ${false}                | ${11}  | ${true}              | ${false}       | ${false}
    ${true}                        | ${false}               | ${true}                 | ${12}  | ${true}              | ${false}       | ${true}
    ${true}                        | ${true}                | ${false}                | ${12}  | ${true}              | ${true}        | ${false}
    ${true}                        | ${true}                | ${true}                 | ${13}  | ${true}              | ${true}        | ${true}
  `(
    'when hasIssuableHealthStatusFeature=$hasIssuableHealthStatusFeature, hasIssueWeightsFeature=$hasIssueWeightsFeature and hasBlockedIssuesFeature=$hasBlockedIssuesFeature',
    ({
      hasIssuableHealthStatusFeature,
      hasIssueWeightsFeature,
      hasBlockedIssuesFeature,
      length,
      containsHealthStatus,
      containsWeight,
      containsBlocking,
    }) => {
      const sortOptions = getSortOptions({
        hasBlockedIssuesFeature,
        hasIssuableHealthStatusFeature,
        hasIssueWeightsFeature,
      });

      it('returns the correct length of sort options', () => {
        expect(sortOptions).toHaveLength(length);
      });

      it(`${containsHealthStatus ? 'contains' : 'does not contain'} health status option`, () => {
        expect(sortOptions.some((option) => option.title === 'Health')).toBe(containsHealthStatus);
      });

      it(`${containsWeight ? 'contains' : 'does not contain'} weight option`, () => {
        expect(sortOptions.some((option) => option.title === 'Weight')).toBe(containsWeight);
      });

      it(`${containsBlocking ? 'contains' : 'does not contain'} blocking option`, () => {
        expect(sortOptions.some((option) => option.title === 'Blocking')).toBe(containsBlocking);
      });
    },
  );
});

describe('getFilterTokens', () => {
  it('returns filtered tokens given "window.location.search"', () => {
    expect(getFilterTokens(locationSearch)).toEqual(filteredTokens);
  });

  it('returns filtered tokens given "window.location.search" with wildcard values', () => {
    expect(getFilterTokens(locationSearchWithWildcardValues)).toEqual(
      filteredTokensWithWildcardValues,
    );
  });
});

describe('convertToApiParams', () => {
  beforeEach(() => {
    setWindowLocation(TEST_HOST);
  });

  it('returns api params given filtered tokens', () => {
    expect(convertToApiParams(filteredTokens)).toEqual(apiParams);
  });

  it('returns api params given filtered tokens with wildcard values', () => {
    expect(convertToApiParams(filteredTokensWithWildcardValues)).toEqual(
      apiParamsWithWildcardValues,
    );
  });
});

describe('convertToUrlParams', () => {
  beforeEach(() => {
    setWindowLocation(TEST_HOST);
  });

  it('returns url params given filtered tokens', () => {
    expect(convertToUrlParams(filteredTokens)).toEqual(urlParams);
  });

  it('returns url params given filtered tokens with wildcard values', () => {
    setWindowLocation('?assignee_id=123');

    expect(convertToUrlParams(filteredTokensWithWildcardValues)).toEqual(
      urlParamsWithWildcardValues,
    );
  });
});

describe('convertToSearchQuery', () => {
  it('returns search string given filtered tokens', () => {
    expect(convertToSearchQuery(filteredTokens)).toBe('find issues');
  });
});

describe('groupMultiSelectFilterTokens', () => {
  it('groups multiSelect filter tokens with || and != operators', () => {
    expect(
      groupMultiSelectFilterTokens(filteredTokens, [
        { type: 'assignee', multiSelect: true },
        { type: 'author', multiSelect: true },
        { type: 'label', multiSelect: true },
      ]),
    ).toEqual(groupedFilteredTokens);
  });
});
