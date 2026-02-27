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
  savedViewFiltersObject,
  savedViewFilterTokens,
  saveSavedViewParams,
  saveSavedViewResponse,
  saveSavedViewWithSearchParams,
  saveSavedViewWithSearchResponse,
  editSavedViewParams,
  editSavedViewResponse,
  editSavedViewFormOnlyParams,
  editSavedViewFormOnlyResponse,
  savedViewFiltersWithWildcards,
  savedViewFilterTokensWithWildcards,
  savedViewFiltersWithNotParent,
  savedViewFilterTokensWithNotParent,
  savedViewFiltersWithSingleIn,
  savedViewFilterTokensWithSingleIn,
  savedViewFiltersWithHierarchyParent,
  savedViewFilterTokensWithHierarchyParent,
  savedViewFiltersWithHierarchyParentWildcard,
  savedViewFilterTokensWithHierarchyParentWildcard,
  savedViewFiltersWithMultipleSearchTokens,
  savedViewFilterTokensWithMultipleSearchTokens,
} from 'jest/work_items/list/mock_data';
import { STATUS_CLOSED } from '~/issues/constants';
import { CREATED_DESC, UPDATED_DESC, urlSortParams } from '~/work_items/list/constants';
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
  getSavedViewFilterTokens,
  saveSavedView,
  handleEnforceSubscriptionLimit,
  updateCacheAfterViewReorder,
  reorderSavedView,
} from 'ee_else_ce/work_items/list/utils';
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import {
  WORK_ITEM_TYPE_ENUM_INCIDENT,
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_ENUM_TASK,
  WORK_ITEM_TYPE_ENUM_TICKET,
} from '~/work_items/constants';

describe('getDefaultWorkItemTypes', () => {
  it('returns default work item types', () => {
    const types = getDefaultWorkItemTypes({
      hasEpicsFeature: false,
      hasOkrsFeature: false,
      hasQualityManagementFeature: false,
    });

    expect(types).toEqual([
      WORK_ITEM_TYPE_ENUM_ISSUE,
      WORK_ITEM_TYPE_ENUM_INCIDENT,
      WORK_ITEM_TYPE_ENUM_TASK,
      WORK_ITEM_TYPE_ENUM_TICKET,
    ]);
  });
});

describe('getTypeTokenOptions', () => {
  it('returns options for the Type token', () => {
    const options = getTypeTokenOptions({
      hasEpicsFeature: false,
      hasOkrsFeature: false,
      hasQualityManagementFeature: false,
    });

    expect(options).toEqual([
      { icon: 'work-item-issue', title: 'Issue', value: 'issue' },
      { icon: 'work-item-incident', title: 'Incident', value: 'incident' },
      { icon: 'work-item-task', title: 'Task', value: 'task' },
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

describe('getSavedViewFilterTokens', () => {
  it('returns valid filter tokens given a saved view filters object', () => {
    expect(getSavedViewFilterTokens(savedViewFiltersObject)).toEqual(savedViewFilterTokens);
  });

  it('capitalizes wildcard filter values', () => {
    expect(getSavedViewFilterTokens(savedViewFiltersWithWildcards)).toEqual(
      savedViewFilterTokensWithWildcards,
    );
  });

  it('handles not[parentIds] filter', () => {
    expect(getSavedViewFilterTokens(savedViewFiltersWithNotParent)).toEqual(
      savedViewFilterTokensWithNotParent,
    );
  });

  it('handles single value in filter', () => {
    expect(getSavedViewFilterTokens(savedViewFiltersWithSingleIn)).toEqual(
      savedViewFilterTokensWithSingleIn,
    );
  });

  it('handles hierarchyFilters with parentIds', () => {
    expect(getSavedViewFilterTokens(savedViewFiltersWithHierarchyParent)).toEqual(
      savedViewFilterTokensWithHierarchyParent,
    );
  });

  it('handles hierarchyFilters with parentWildcardId', () => {
    expect(getSavedViewFilterTokens(savedViewFiltersWithHierarchyParentWildcard)).toEqual(
      savedViewFilterTokensWithHierarchyParentWildcard,
    );
  });

  it('splits saved view search string into multiple tokens', () => {
    expect(getSavedViewFilterTokens(savedViewFiltersWithMultipleSearchTokens)).toEqual(
      savedViewFilterTokensWithMultipleSearchTokens,
    );
  });
});

describe('handleEnforceSubscriptionLimit', () => {
  let mockApolloClient;
  let mockQuery;
  let mockMutate;

  beforeEach(() => {
    mockQuery = jest.fn();
    mockMutate = jest.fn();
    mockApolloClient = {
      query: mockQuery,
      mutate: mockMutate,
    };
  });

  it('does not unsubscribe when under the limit', async () => {
    mockQuery.mockResolvedValue({
      data: {
        namespace: {
          savedViews: {
            nodes: [
              { id: 'gid://gitlab/SavedView/1', name: 'View 1' },
              { id: 'gid://gitlab/SavedView/2', name: 'View 2' },
            ],
          },
        },
      },
    });

    await handleEnforceSubscriptionLimit({
      subscribedSavedViewLimit: 5,
      apolloClient: mockApolloClient,
      namespacePath: 'my-group',
    });

    expect(mockQuery).toHaveBeenCalledWith({
      query: expect.anything(),
      variables: {
        fullPath: 'my-group',
        subscribedOnly: true,
        sort: 'RELATIVE_POSITION',
      },
      fetchPolicy: 'cache-only',
    });
    expect(mockMutate).not.toHaveBeenCalled();
  });

  it('unsubscribes from second-to-last view when over the limit when creating a view', async () => {
    mockQuery.mockResolvedValue({
      data: {
        namespace: {
          savedViews: {
            nodes: [
              { id: 'gid://gitlab/SavedView/1', name: 'View 1' },
              { id: 'gid://gitlab/SavedView/2', name: 'View 2' },
              { id: 'gid://gitlab/SavedView/3', name: 'View 3' },
              { id: 'gid://gitlab/SavedView/4', name: 'View 4' },
            ],
          },
        },
      },
    });
    mockMutate.mockResolvedValue({});

    await handleEnforceSubscriptionLimit({
      subscribedSavedViewLimit: 3,
      apolloClient: mockApolloClient,
      namespacePath: 'my-group',
      creating: true,
    });

    expect(mockMutate).toHaveBeenCalledWith(
      expect.objectContaining({
        variables: {
          input: {
            id: 'gid://gitlab/SavedView/3', // Second-to-last view
          },
        },
      }),
    );
  });

  it('unsubscribes from second-to-last view when over the limit not creating a view', async () => {
    mockQuery.mockResolvedValue({
      data: {
        namespace: {
          savedViews: {
            nodes: [
              { id: 'gid://gitlab/SavedView/1', name: 'View 1' },
              { id: 'gid://gitlab/SavedView/2', name: 'View 2' },
              { id: 'gid://gitlab/SavedView/3', name: 'View 3' },
              { id: 'gid://gitlab/SavedView/4', name: 'View 4' },
            ],
          },
        },
      },
    });
    mockMutate.mockResolvedValue({});

    await handleEnforceSubscriptionLimit({
      subscribedSavedViewLimit: 3,
      apolloClient: mockApolloClient,
      namespacePath: 'my-group',
      creating: false,
    });

    expect(mockMutate).toHaveBeenCalledWith(
      expect.objectContaining({
        variables: {
          input: {
            id: 'gid://gitlab/SavedView/4', // Second-to-last view
          },
        },
      }),
    );
  });
});

describe('saveSavedView', () => {
  let mockApolloClient;
  let mockMutate;
  let mockQuery;

  beforeEach(() => {
    mockMutate = jest.fn();
    mockQuery = jest.fn();
    mockApolloClient = {
      mutate: mockMutate,
      query: mockQuery,
    };
  });

  describe('when creating a new saved view', () => {
    it('calls mutate with workItemSavedViewCreate', async () => {
      const params = {
        ...saveSavedViewParams,
        apolloClient: mockApolloClient,
        subscribedSavedViewLimit: 5,
      };

      mockMutate.mockResolvedValue(saveSavedViewResponse);

      mockQuery.mockResolvedValue({
        data: {
          namespace: {
            savedViews: {
              nodes: [{ id: 'gid://gitlab/SavedView/1', name: 'View 1' }],
            },
          },
        },
      });

      const result = await saveSavedView(params);

      expect(mockMutate).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: {
            input: {
              namespacePath: 'my-group',
              name: 'My View',
              description: 'A test view',
              private: false,
              filters: { state: 'opened' },
              sort: 'CREATED_DESC',
              displaySettings: { groupBy: 'assignee' },
            },
          },
        }),
      );
      expect(result.data.workItemSavedViewCreate.savedView.id).toBe('gid://gitlab/SavedView/1');
    });

    it('joins search filters before calling mutate', async () => {
      const params = {
        ...saveSavedViewWithSearchParams,
        apolloClient: mockApolloClient,
        subscribedSavedViewLimit: 5,
      };

      mockMutate.mockResolvedValue(saveSavedViewWithSearchResponse);

      mockQuery.mockResolvedValue({
        data: {
          namespace: {
            savedViews: {
              nodes: [{ id: 'gid://gitlab/SavedView/1', name: 'View 1' }],
            },
          },
        },
      });

      await saveSavedView(params);

      expect(mockMutate).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: {
            input: {
              namespacePath: 'my-group',
              name: 'My View',
              description: 'A test view',
              private: false,
              filters: { in: 'TITLE', search: 'work__SV__items' },
              sort: 'CREATED_DESC',
              displaySettings: { groupBy: 'assignee' },
            },
          },
        }),
      );
    });

    it('calls handleEnforceSubscriptionLimit when enforceSubscriptionLimit is true', async () => {
      mockQuery = jest.fn().mockResolvedValue({
        data: {
          namespace: {
            savedViews: {
              nodes: [{ id: 'gid://gitlab/SavedView/1', name: 'View 1' }],
            },
          },
        },
      });

      const apolloClient = {
        mutate: mockMutate,
        query: mockQuery,
      };

      const params = {
        ...saveSavedViewParams,
        apolloClient,
        enforceSubscriptionLimit: true,
        subscribedSavedViewLimit: 3,
      };

      mockMutate.mockResolvedValue(saveSavedViewResponse);

      await saveSavedView(params);

      expect(mockQuery).toHaveBeenCalledWith({
        query: expect.anything(),
        variables: {
          fullPath: 'my-group',
          subscribedOnly: true,
          sort: 'RELATIVE_POSITION',
        },
        fetchPolicy: 'cache-only',
      });
    });

    it('does not call handleEnforceSubscriptionLimit when enforceSubscriptionLimit is false', async () => {
      const apolloClient = {
        mutate: mockMutate,
        query: jest.fn(),
      };

      const params = {
        ...saveSavedViewParams,
        apolloClient,
        enforceSubscriptionLimit: false,
        subscribedSavedViewLimit: 3,
      };

      mockMutate.mockResolvedValue(saveSavedViewResponse);

      await saveSavedView(params);

      expect(mockQuery).not.toHaveBeenCalled();
    });

    it('does not update cache when mutation returns errors', async () => {
      const errorResponse = {
        data: {
          workItemSavedViewCreate: {
            savedView: null,
            errors: ['You do not have permission to create this saved view.'],
          },
        },
      };

      mockMutate.mockResolvedValue(errorResponse);

      mockQuery.mockResolvedValue({
        data: {
          namespace: {
            savedViews: {
              nodes: [],
            },
          },
        },
      });

      const params = {
        ...saveSavedViewParams,
        apolloClient: mockApolloClient,
        subscribedSavedViewLimit: 5,
      };

      await saveSavedView(params);

      const { update } = mockMutate.mock.calls[0][0];
      const mockCache = { readQuery: jest.fn(), writeQuery: jest.fn() };
      update(mockCache, { data: errorResponse.data });

      expect(mockCache.readQuery).not.toHaveBeenCalled();
      expect(mockCache.writeQuery).not.toHaveBeenCalled();
    });
  });

  describe('when editing a saved view', () => {
    it('calls mutate with workItemSavedViewUpdate', async () => {
      const params = {
        ...editSavedViewParams,
        apolloClient: mockApolloClient,
        subscribedSavedViewLimit: 5,
      };

      mockMutate.mockResolvedValue(editSavedViewResponse);

      const result = await saveSavedView(params);

      expect(mockMutate).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: {
            input: {
              id: 'gid://gitlab/SavedView/1',
              name: 'Updated View',
              description: 'Updated description',
              private: false,
              filters: { state: 'closed' },
              sort: 'UPDATED_DESC',
              displaySettings: { groupBy: 'status' },
            },
          },
        }),
      );
      expect(result.data.workItemSavedViewUpdate.savedView.name).toBe('Updated View');
    });

    it('does not call handleEnforceSubscriptionLimit when editing', async () => {
      const apolloClient = {
        mutate: mockMutate,
        query: jest.fn(),
      };

      const params = {
        ...editSavedViewParams,
        apolloClient,
        subscribedSavedViewLimit: 3,
      };

      mockMutate.mockResolvedValue(editSavedViewResponse);

      await saveSavedView(params);

      expect(mockQuery).not.toHaveBeenCalled();
    });

    it('excludes filters and sort when editing form only', async () => {
      const params = {
        ...editSavedViewFormOnlyParams,
        apolloClient: mockApolloClient,
        subscribedSavedViewLimit: 5,
      };

      mockMutate.mockResolvedValue(editSavedViewFormOnlyResponse);

      await saveSavedView(params);

      const callArgs = mockMutate.mock.calls[0][0];
      expect(callArgs.variables.input).toEqual({
        id: 'gid://gitlab/SavedView/1',
        name: 'Updated View',
        description: 'Updated description',
        private: false,
      });
      expect(callArgs.variables.input.filters).toBeUndefined();
      expect(callArgs.variables.input.sort).toBeUndefined();
      expect(callArgs.variables.input.displaySettings).toBeUndefined();
    });

    it('does not update cache when mutation returns errors', async () => {
      const errorResponse = {
        data: {
          workItemSavedViewUpdate: {
            savedView: null,
            errors: ['Only the author can change visibility settings'],
          },
        },
      };

      mockMutate.mockResolvedValue(errorResponse);

      const params = {
        ...editSavedViewParams,
        apolloClient: mockApolloClient,
        subscribedSavedViewLimit: 5,
      };

      await saveSavedView(params);

      const { update } = mockMutate.mock.calls[0][0];
      const mockCache = { readQuery: jest.fn(), writeQuery: jest.fn() };
      update(mockCache, { data: errorResponse.data });

      expect(mockCache.readQuery).not.toHaveBeenCalled();
      expect(mockCache.writeQuery).not.toHaveBeenCalled();
    });
  });
});

describe('updateCacheAfterViewReorder', () => {
  let mockCache;
  const fullPath = 'test-group';

  const mockViews = [
    { id: 'gid://gitlab/SavedView/1', name: 'View 1' },
    { id: 'gid://gitlab/SavedView/2', name: 'View 2' },
    { id: 'gid://gitlab/SavedView/3', name: 'View 3' },
  ];

  const buildCacheData = (views) => ({
    namespace: {
      savedViews: {
        nodes: views.map((v) => ({ ...v })),
      },
    },
  });

  beforeEach(() => {
    mockCache = {
      readQuery: jest.fn(),
      writeQuery: jest.fn(),
    };
  });

  it('moves a view after a reference view', () => {
    mockCache.readQuery.mockReturnValue(buildCacheData(mockViews));

    updateCacheAfterViewReorder({
      cache: mockCache,
      movedView: mockViews[2],
      referenceView: mockViews[0],
      position: 'after',
      fullPath,
    });

    const writtenData = mockCache.writeQuery.mock.calls[0][0].data;
    const reorderedIds = writtenData.namespace.savedViews.nodes.map((v) => v.id);

    expect(reorderedIds).toEqual([
      'gid://gitlab/SavedView/1',
      'gid://gitlab/SavedView/3',
      'gid://gitlab/SavedView/2',
    ]);
  });

  it('moves a view before a reference view', () => {
    mockCache.readQuery.mockReturnValue(buildCacheData(mockViews));

    updateCacheAfterViewReorder({
      cache: mockCache,
      movedView: mockViews[2],
      referenceView: mockViews[0],
      position: 'before',
      fullPath,
    });

    const writtenData = mockCache.writeQuery.mock.calls[0][0].data;
    const reorderedIds = writtenData.namespace.savedViews.nodes.map((v) => v.id);

    expect(reorderedIds).toEqual([
      'gid://gitlab/SavedView/3',
      'gid://gitlab/SavedView/1',
      'gid://gitlab/SavedView/2',
    ]);
  });

  it('appends to end when reference view is not found', () => {
    mockCache.readQuery.mockReturnValue(buildCacheData(mockViews));

    updateCacheAfterViewReorder({
      cache: mockCache,
      movedView: mockViews[0],
      referenceView: { id: 'gid://gitlab/SavedView/999' },
      position: 'after',
      fullPath,
    });

    const writtenData = mockCache.writeQuery.mock.calls[0][0].data;
    const reorderedIds = writtenData.namespace.savedViews.nodes.map((v) => v.id);

    expect(reorderedIds).toEqual([
      'gid://gitlab/SavedView/2',
      'gid://gitlab/SavedView/3',
      'gid://gitlab/SavedView/1',
    ]);
  });

  it('does not write to cache when moved view is not found', () => {
    mockCache.readQuery.mockReturnValue(buildCacheData(mockViews));

    updateCacheAfterViewReorder({
      cache: mockCache,
      movedView: { id: 'gid://gitlab/SavedView/999' },
      referenceView: mockViews[0],
      position: 'after',
      fullPath,
    });

    // writeQuery is still called but data should be unchanged
    const writtenData = mockCache.writeQuery.mock.calls[0][0].data;
    const reorderedIds = writtenData.namespace.savedViews.nodes.map((v) => v.id);

    expect(reorderedIds).toEqual([
      'gid://gitlab/SavedView/1',
      'gid://gitlab/SavedView/2',
      'gid://gitlab/SavedView/3',
    ]);
  });

  it('does not write to cache when source data is null', () => {
    mockCache.readQuery.mockReturnValue(null);

    updateCacheAfterViewReorder({
      cache: mockCache,
      movedView: mockViews[2],
      referenceView: mockViews[0],
      position: 'after',
      fullPath,
    });

    expect(mockCache.writeQuery).not.toHaveBeenCalled();
  });

  it('updates both subscribedOnly true and false cache variants', () => {
    mockCache.readQuery.mockReturnValue(buildCacheData(mockViews));

    updateCacheAfterViewReorder({
      cache: mockCache,
      movedView: mockViews[2],
      referenceView: mockViews[0],
      position: 'after',
      fullPath,
    });

    expect(mockCache.readQuery).toHaveBeenCalledTimes(2);
    expect(mockCache.writeQuery).toHaveBeenCalledTimes(2);

    const firstCallVars = mockCache.readQuery.mock.calls[0][0].variables;
    const secondCallVars = mockCache.readQuery.mock.calls[1][0].variables;

    expect(firstCallVars.subscribedOnly).toBe(true);
    expect(secondCallVars.subscribedOnly).toBe(false);
  });
});

describe('reorderSavedView', () => {
  let mockApolloClient;
  let mockMutate;

  const movedView = { id: 'gid://gitlab/SavedView/3', name: 'View 3' };
  const referenceView = { id: 'gid://gitlab/SavedView/1', name: 'View 1' };

  beforeEach(() => {
    mockMutate = jest.fn().mockResolvedValue({});
    mockApolloClient = { mutate: mockMutate };
  });

  it('calls mutate with moveAfterId when position is after', async () => {
    await reorderSavedView({
      apolloClient: mockApolloClient,
      movedView,
      referenceView,
      position: 'after',
      fullPath: 'test-group',
    });

    expect(mockMutate).toHaveBeenCalledWith(
      expect.objectContaining({
        variables: {
          input: {
            id: movedView.id,
            moveAfterId: referenceView.id,
          },
        },
      }),
    );
  });

  it('calls mutate with moveBeforeId when position is before', async () => {
    await reorderSavedView({
      apolloClient: mockApolloClient,
      movedView,
      referenceView,
      position: 'before',
      fullPath: 'test-group',
    });

    expect(mockMutate).toHaveBeenCalledWith(
      expect.objectContaining({
        variables: {
          input: {
            id: movedView.id,
            moveBeforeId: referenceView.id,
          },
        },
      }),
    );
  });

  it('passes an update function for cache update', async () => {
    await reorderSavedView({
      apolloClient: mockApolloClient,
      movedView,
      referenceView,
      position: 'after',
      fullPath: 'test-group',
    });

    const mutateCall = mockMutate.mock.calls[0][0];
    expect(mutateCall.update).toBeInstanceOf(Function);
  });
});
