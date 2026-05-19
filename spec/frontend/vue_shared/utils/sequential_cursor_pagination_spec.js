import SequentialCursorPaginator from '~/vue_shared/utils/sequential_cursor_pagination';
import { fetchPolicies } from '~/lib/graphql';

describe('SequentialCursorPaginator', () => {
  let mockApollo;
  let paginator;
  let mockResources;

  const createMockResource = (overrides = {}) => ({
    query: { kind: 'Document' },
    first: 'first',
    after: 'after',
    last: 'last',
    before: 'before',
    getNodes: jest.fn((result) => result?.data?.items || []),
    getPageInfo: jest.fn((result) => result?.data?.pageInfo || {}),
    baseVariables: {},
    ...overrides,
  });

  const createMockQueryResult = (items, pageInfo) => ({
    data: {
      items,
      pageInfo,
    },
  });

  const createEmptyPageInfo = () => ({
    hasNextPage: false,
    hasPreviousPage: false,
    endCursor: null,
    startCursor: null,
  });

  const mockEmptyMetadataQueries = (count) => {
    for (let i = 0; i < count; i += 1) {
      mockApollo.query.mockResolvedValueOnce(createMockQueryResult([], createEmptyPageInfo()));
    }
  };

  beforeEach(() => {
    mockApollo = {
      query: jest.fn(),
    };

    mockResources = [createMockResource(), createMockResource(), createMockResource()];
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('constructor', () => {
    it('initializes with default page size', () => {
      paginator = new SequentialCursorPaginator(mockApollo, mockResources);

      expect(paginator.$apollo).toBe(mockApollo);
      expect(paginator.resources).toBe(mockResources);
      expect(paginator.pageSize).toBe(20);
      expect(paginator.resourceStartIndex).toBe(0);
      expect(paginator.resourceEndIndex).toBe(0);
      expect(paginator.beforePageCursor).toBeNull();
    });

    it('initializes with custom page size', () => {
      paginator = new SequentialCursorPaginator(mockApollo, mockResources, 50);

      expect(paginator.pageSize).toBe(50);
    });
  });

  describe('reset', () => {
    beforeEach(() => {
      paginator = new SequentialCursorPaginator(mockApollo, mockResources, 5);
    });

    it('resets pagination state and returns initial page', async () => {
      paginator.resourceStartIndex = 2;
      paginator.resourceEndIndex = 2;
      paginator.beforePageCursor = 'cursor123';
      paginator.resources[0].cachedPageInfo = { hasNextPage: true };

      // Mock for main query (resource 0)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }, { id: 2 }, { id: 3 }], {
          hasNextPage: true,
          hasPreviousPage: false,
          endCursor: 'end1',
          startCursor: 'start1',
        }),
      );
      // Mock for checkIfAnyResourceHasMorePages (resources 1-2)
      mockEmptyMetadataQueries(2);

      const result = await paginator.reset({ projectId: '123' });

      expect(paginator.resourceStartIndex).toBe(0);
      expect(paginator.beforePageCursor).toBeNull();
      expect(paginator.resources[0].cachedPageInfo).toStrictEqual({
        endCursor: 'end1',
        hasNextPage: true,
        hasPreviousPage: false,
        startCursor: 'start1',
      });
      expect(result).toHaveLength(3);
    });

    it('passes variables to getNextCombinedPage', async () => {
      // Mock for main query (resource 0)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }], createEmptyPageInfo()),
      );
      // Mock for checkIfAnyResourceHasMorePages (resources 1-2)
      mockEmptyMetadataQueries(2);

      const variables = { projectId: '456', filter: 'active' };
      await paginator.reset(variables);

      expect(mockApollo.query).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: expect.objectContaining(variables),
        }),
      );
    });
  });

  describe('refetch', () => {
    beforeEach(() => {
      paginator = new SequentialCursorPaginator(mockApollo, mockResources, 5);
    });

    it('calls reset when on first page (no beforePageCursor)', async () => {
      jest.spyOn(paginator, 'reset');
      paginator.beforePageCursor = null;

      // Mock for main query (resource 0)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }], createEmptyPageInfo()),
      );
      // Mock for checkIfAnyResourceHasMorePages (resources 1-2)
      mockEmptyMetadataQueries(2);

      await paginator.refetch({ projectId: '123' });

      expect(paginator.reset).toHaveBeenCalledWith({ projectId: '123' });
    });

    it('refetches current page using beforePageCursor', async () => {
      paginator.resourceStartIndex = 1;
      paginator.resourceEndIndex = 2;
      paginator.beforePageCursor = 'cursor123';

      // Mock for checkIfAnyResourceHasMorePages (previous resource 0)
      mockEmptyMetadataQueries(1);
      // Mock for main query
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }, { id: 2 }], {
          hasNextPage: true,
          hasPreviousPage: true,
          endCursor: 'end1',
          startCursor: 'start1',
        }),
      );
      // Mock for checkIfAnyResourceHasMorePages (next resource 2)
      mockEmptyMetadataQueries(1);

      await paginator.refetch({ projectId: '123' });

      expect(paginator.resources[1].cachedPageInfo.hasNextPage).toBe(true);
      expect(paginator.resources[1].cachedPageInfo.endCursor).toBe('end1');
    });
  });

  describe('getPageFromResource', () => {
    beforeEach(() => {
      paginator = new SequentialCursorPaginator(mockApollo, mockResources, 5);
    });

    it('fetches data from resource and caches pageInfo', async () => {
      const mockResult = createMockQueryResult([{ id: 1 }, { id: 2 }], {
        hasNextPage: true,
        hasPreviousPage: false,
        endCursor: 'end1',
        startCursor: 'start1',
      });

      mockApollo.query.mockResolvedValue(mockResult);

      const resource = mockResources[0];
      const variables = { first: 5, after: null };
      const result = await paginator.getPageFromResource(resource, 0, variables);

      expect(mockApollo.query).toHaveBeenCalledWith({
        query: resource.query,
        variables,
        fetchPolicy: fetchPolicies.NETWORK_ONLY,
      });
      expect(result).toEqual([{ id: 1 }, { id: 2 }]);
      expect(paginator.resources[0].cachedPageInfo).toEqual({
        hasNextPage: true,
        hasPreviousPage: false,
        endCursor: 'end1',
        startCursor: 'start1',
      });
    });

    it('merges baseVariables with provided variables', async () => {
      const resource = createMockResource({
        baseVariables: { projectId: '123', status: 'active' },
      });

      mockApollo.query.mockResolvedValue(createMockQueryResult([{ id: 1 }], createEmptyPageInfo()));

      await paginator.getPageFromResource(resource, 0, { first: 5 });

      expect(mockApollo.query).toHaveBeenCalledWith({
        query: resource.query,
        variables: { projectId: '123', status: 'active', first: 5 },
        fetchPolicy: fetchPolicies.NETWORK_ONLY,
      });
    });

    it('rejects with a timeout error when the request exceeds the timeout', async () => {
      jest.useFakeTimers();

      const resource = createMockResource({ timeout: 1000 });
      mockApollo.query.mockReturnValue(new Promise(() => {}));

      const promise = paginator.getPageFromResource(resource, 0, { first: 5 });
      jest.advanceTimersByTime(1000);

      await expect(promise).rejects.toThrow('Request timed out after 1000ms');
    });
  });

  describe('getNextCombinedPage', () => {
    beforeEach(() => {
      paginator = new SequentialCursorPaginator(mockApollo, mockResources, 5);
    });

    it('fetches items from single resource when it has enough items', async () => {
      // Mock for main query
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }], {
          hasNextPage: true,
          hasPreviousPage: false,
          endCursor: 'end1',
          startCursor: 'start1',
        }),
      );
      // Mock for checkIfAnyResourceHasMorePages (resources 1-2)
      mockEmptyMetadataQueries(2);

      const result = await paginator.getNextCombinedPage({ projectId: '123' });

      expect(result).toHaveLength(5);
      expect(result).toEqual([{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }]);
      expect(paginator.resourceStartIndex).toBe(0);
      expect(paginator.resourceEndIndex).toBe(0);
    });

    it('combines items from multiple resources to fill page', async () => {
      // Mock for main query (resource 0)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }, { id: 2 }], {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'end1',
          startCursor: 'start1',
        }),
      );
      // Mock for main query (resource 1)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 3 }, { id: 4 }, { id: 5 }], {
          hasNextPage: true,
          hasPreviousPage: false,
          endCursor: 'end2',
          startCursor: 'start2',
        }),
      );
      // Mock for checkIfAnyResourceHasMorePages (resource 2)
      mockEmptyMetadataQueries(1);

      const result = await paginator.getNextCombinedPage({ projectId: '123' });

      expect(result).toHaveLength(5);
      expect(result).toEqual([{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }]);
      expect(paginator.resourceStartIndex).toBe(0);
      expect(paginator.resourceEndIndex).toBe(1);
    });

    it('uses cached endCursor for subsequent pages', async () => {
      paginator.resources[0].cachedPageInfo = {
        hasNextPage: true,
        endCursor: 'cursor123',
      };

      // Mock for main query (resource 0)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 6 }, { id: 7 }, { id: 8 }, { id: 9 }, { id: 10 }], {
          hasNextPage: true,
          hasPreviousPage: true,
          endCursor: 'end2',
          startCursor: 'start2',
        }),
      );
      // Mock for checkIfAnyResourceHasMorePages (resources 1-2)
      mockEmptyMetadataQueries(2);

      await paginator.getNextCombinedPage({ projectId: '123' });

      expect(mockApollo.query).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: expect.objectContaining({
            first: 5,
            after: 'cursor123',
          }),
        }),
      );
    });

    it('stores beforePageCursor for refetching', async () => {
      paginator.resources[0].cachedPageInfo = {
        hasNextPage: true,
        endCursor: 'cursor123',
      };

      // Mock for main query (resource 0)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }], {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'end1',
          startCursor: 'start1',
        }),
      );
      // Mock for checkIfAnyResourceHasMorePages (resources 1-2)
      mockEmptyMetadataQueries(2);

      await paginator.getNextCombinedPage({ projectId: '123' });

      expect(paginator.beforePageCursor).toBe('cursor123');
    });

    it('checks all resources in direction for pagination metadata', async () => {
      jest.spyOn(paginator, 'checkIfAnyResourceHasMorePages');

      mockApollo.query.mockResolvedValue(
        createMockQueryResult([{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }], {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'end1',
          startCursor: 'start1',
        }),
      );

      await paginator.getNextCombinedPage({ projectId: '123' });

      // Check all previous resources (starting from index -1)
      expect(paginator.checkIfAnyResourceHasMorePages).toHaveBeenCalledWith('PREVIOUS', -1, {
        projectId: '123',
      });
      // Check all next resources (starting from index 1)
      expect(paginator.checkIfAnyResourceHasMorePages).toHaveBeenCalledWith('NEXT', 1, {
        projectId: '123',
      });
    });

    it('handles empty resources', async () => {
      // Mock for main query (resource 0 - empty)
      mockApollo.query.mockResolvedValueOnce(createMockQueryResult([], createEmptyPageInfo()));
      // Mock for main query (resource 1 - has items)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }, { id: 2 }], {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'end2',
          startCursor: 'start2',
        }),
      );
      // Mock for main query (resource 2 - to fill remaining items if needed)
      mockApollo.query.mockResolvedValueOnce(createMockQueryResult([], createEmptyPageInfo()));

      const result = await paginator.getNextCombinedPage({ projectId: '123' });

      expect(result).toEqual([{ id: 1 }, { id: 2 }]);
    });
  });

  describe('getPreviousCombinedPage', () => {
    beforeEach(() => {
      paginator = new SequentialCursorPaginator(mockApollo, mockResources, 5);
    });

    it('fetches items from single resource in reverse', async () => {
      paginator.resourceStartIndex = 1;
      paginator.resources[1].cachedPageInfo = {
        hasPreviousPage: true,
        startCursor: 'start1',
      };

      // Mock for checkIfAnyResourceHasMorePages (next resource, index 2)
      mockEmptyMetadataQueries(1);
      // Mock for main query (resource 1)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }], {
          hasNextPage: true,
          hasPreviousPage: true,
          endCursor: 'end1',
          startCursor: 'start0',
        }),
      );
      // Mock for checkIfAnyResourceHasMorePages (previous resource, index 0)
      mockEmptyMetadataQueries(1);

      const result = await paginator.getPreviousCombinedPage({ projectId: '123' });

      expect(result).toHaveLength(5);
      expect(result).toEqual([{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }]);
      expect(paginator.resourceStartIndex).toBe(1);
      expect(paginator.resourceEndIndex).toBe(1);
    });

    it('combines items from multiple resources in reverse', async () => {
      paginator.resourceStartIndex = 1;
      paginator.resources[1].cachedPageInfo = {
        hasPreviousPage: true,
        startCursor: 'start1',
      };

      // Mock for checkIfAnyResourceHasMorePages (next resource, index 2)
      mockEmptyMetadataQueries(1);
      // Mock for main query (resource 1)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 3 }, { id: 4 }, { id: 5 }], {
          hasNextPage: true,
          hasPreviousPage: true,
          endCursor: 'end1',
          startCursor: 'start1',
        }),
      );
      // Mock for main query (resource 0)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }, { id: 2 }], {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'end0',
          startCursor: 'start0',
        }),
      );

      const result = await paginator.getPreviousCombinedPage({ projectId: '123' });

      expect(result).toHaveLength(5);
      expect(result).toEqual([{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }]);
      expect(paginator.resourceStartIndex).toBe(0);
      expect(paginator.resourceEndIndex).toBe(1);
    });

    it('uses cached startCursor for pagination', async () => {
      paginator.resourceStartIndex = 1;
      paginator.resources[1].cachedPageInfo = {
        hasPreviousPage: true,
        startCursor: 'cursor123',
      };

      // Mock for checkIfAnyResourceHasMorePages (next resource, index 2)
      mockEmptyMetadataQueries(1);
      // Mock for main query (resource 1)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }], {
          hasNextPage: true,
          hasPreviousPage: true,
          endCursor: 'end1',
          startCursor: 'start1',
        }),
      );
      // Mock for checkIfAnyResourceHasMorePages (previous resource, index 0)
      mockEmptyMetadataQueries(1);

      await paginator.getPreviousCombinedPage({ projectId: '123' });

      expect(mockApollo.query).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: expect.objectContaining({
            last: 5,
            before: 'cursor123',
          }),
        }),
      );
    });

    it('stores beforePageCursor for refetching', async () => {
      paginator.resourceStartIndex = 1;
      paginator.resources[1].cachedPageInfo = {
        hasPreviousPage: true,
        startCursor: 'cursor123',
      };

      // Mock for checkIfAnyResourceHasMorePages (next resource, index 2)
      mockEmptyMetadataQueries(1);
      // Mock for main query (resource 1)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }], {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'end1',
          startCursor: 'start1',
        }),
      );
      // Mock for checkIfAnyResourceHasMorePages (previous resource, index 0)
      mockEmptyMetadataQueries(1);

      await paginator.getPreviousCombinedPage({ projectId: '123' });

      expect(paginator.beforePageCursor).toBe('cursor123');
    });

    it('checks all resources in direction for pagination metadata', async () => {
      jest.spyOn(paginator, 'checkIfAnyResourceHasMorePages');

      paginator.resourceStartIndex = 1;
      paginator.resources[1].cachedPageInfo = {
        hasPreviousPage: true,
        startCursor: 'start1',
      };

      mockApollo.query.mockResolvedValue(
        createMockQueryResult([{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }], {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'end1',
          startCursor: 'start1',
        }),
      );

      await paginator.getPreviousCombinedPage({ projectId: '123' });

      // Check all next resources (starting from index 2)
      expect(paginator.checkIfAnyResourceHasMorePages).toHaveBeenCalledWith('NEXT', 2, {
        projectId: '123',
      });

      // Check all previous resources (starting from index 0)
      expect(paginator.checkIfAnyResourceHasMorePages).toHaveBeenCalledWith('PREVIOUS', 0, {
        projectId: '123',
      });
    });
  });

  describe('checkIfAdjacentResourceHasMorePages', () => {
    beforeEach(() => {
      paginator = new SequentialCursorPaginator(mockApollo, mockResources, 5);
    });

    it('fetches metadata for adjacent resource in NEXT direction', async () => {
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([], {
          hasNextPage: true,
          hasPreviousPage: false,
          endCursor: null,
          startCursor: null,
        }),
      );

      await paginator.checkIfAdjacentResourceHasMorePages('NEXT', 1, { projectId: '123' });

      expect(mockApollo.query).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: expect.objectContaining({
            first: 1,
            after: null,
          }),
        }),
      );
      expect(paginator.resources[1].cachedPageInfo).toEqual({
        hasNextPage: true,
        hasPreviousPage: false,
        endCursor: null,
        startCursor: null,
      });
    });

    it('fetches metadata for adjacent resource in PREVIOUS direction', async () => {
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([], {
          hasNextPage: false,
          hasPreviousPage: true,
          endCursor: null,
          startCursor: null,
        }),
      );

      await paginator.checkIfAdjacentResourceHasMorePages('PREVIOUS', 0, { projectId: '123' });

      expect(mockApollo.query).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: expect.objectContaining({
            last: 1,
            before: null,
          }),
        }),
      );
      expect(paginator.resources[0].cachedPageInfo).toEqual({
        hasNextPage: false,
        hasPreviousPage: true,
        endCursor: null,
        startCursor: null,
      });
    });

    it('does nothing when resource does not exist', async () => {
      await paginator.checkIfAdjacentResourceHasMorePages('NEXT', 10, { projectId: '123' });

      expect(mockApollo.query).not.toHaveBeenCalled();
    });

    it('does nothing when resource index is negative', async () => {
      await paginator.checkIfAdjacentResourceHasMorePages('PREVIOUS', -1, { projectId: '123' });

      expect(mockApollo.query).not.toHaveBeenCalled();
    });
  });

  describe('checkIfAnyResourceHasMorePages', () => {
    beforeEach(() => {
      paginator = new SequentialCursorPaginator(mockApollo, mockResources, 5);
    });

    it('checks all resources from index onwards in NEXT direction', async () => {
      jest.spyOn(paginator, 'checkIfAdjacentResourceHasMorePages');

      mockApollo.query.mockResolvedValue(createMockQueryResult([], createEmptyPageInfo()));

      await paginator.checkIfAnyResourceHasMorePages('NEXT', 1, { projectId: '123' });

      expect(paginator.checkIfAdjacentResourceHasMorePages).toHaveBeenCalledWith('NEXT', 1, {
        projectId: '123',
      });
      expect(paginator.checkIfAdjacentResourceHasMorePages).toHaveBeenCalledWith('NEXT', 2, {
        projectId: '123',
      });
      expect(paginator.checkIfAdjacentResourceHasMorePages).toHaveBeenCalledTimes(2);
    });

    it('checks all resources from index backwards in PREVIOUS direction', async () => {
      jest.spyOn(paginator, 'checkIfAdjacentResourceHasMorePages');

      mockApollo.query.mockResolvedValue(createMockQueryResult([], createEmptyPageInfo()));

      await paginator.checkIfAnyResourceHasMorePages('PREVIOUS', 1, { projectId: '123' });

      expect(paginator.checkIfAdjacentResourceHasMorePages).toHaveBeenCalledWith('PREVIOUS', 1, {
        projectId: '123',
      });
      expect(paginator.checkIfAdjacentResourceHasMorePages).toHaveBeenCalledWith('PREVIOUS', 0, {
        projectId: '123',
      });
      expect(paginator.checkIfAdjacentResourceHasMorePages).toHaveBeenCalledTimes(2);
    });

    it('handles out of bounds index in NEXT direction', async () => {
      jest.spyOn(paginator, 'checkIfAdjacentResourceHasMorePages');

      await paginator.checkIfAnyResourceHasMorePages('NEXT', 10, { projectId: '123' });

      expect(paginator.checkIfAdjacentResourceHasMorePages).not.toHaveBeenCalled();
    });

    it('handles negative index in PREVIOUS direction', async () => {
      jest.spyOn(paginator, 'checkIfAdjacentResourceHasMorePages');

      await paginator.checkIfAnyResourceHasMorePages('PREVIOUS', -1, { projectId: '123' });

      expect(paginator.checkIfAdjacentResourceHasMorePages).not.toHaveBeenCalled();
    });
  });

  describe('hasNextPage', () => {
    beforeEach(() => {
      paginator = new SequentialCursorPaginator(mockApollo, mockResources, 5);
    });

    it('returns true when any resource has next page', () => {
      paginator.resources[0].cachedPageInfo = { hasNextPage: false };
      paginator.resources[1].cachedPageInfo = { hasNextPage: true };
      paginator.resources[2].cachedPageInfo = { hasNextPage: false };

      expect(paginator.hasNextPage()).toBe(true);
    });

    it('returns false when no resources have next page', () => {
      paginator.resources[0].cachedPageInfo = { hasNextPage: false };
      paginator.resources[1].cachedPageInfo = { hasNextPage: false };
      paginator.resources[2].cachedPageInfo = { hasNextPage: false };

      expect(paginator.hasNextPage()).toBe(false);
    });

    it('returns false when no resources have cached pageInfo', () => {
      expect(paginator.hasNextPage()).toBe(false);
    });

    it('handles partial cached pageInfo', () => {
      paginator.resources[0].cachedPageInfo = { hasNextPage: false };
      paginator.resources[2].cachedPageInfo = { hasNextPage: true };

      expect(paginator.hasNextPage()).toBe(true);
    });
  });

  describe('hasPreviousPage', () => {
    beforeEach(() => {
      paginator = new SequentialCursorPaginator(mockApollo, mockResources, 5);
    });

    it('returns true when any resource has previous page', () => {
      paginator.resources[0].cachedPageInfo = { hasPreviousPage: false };
      paginator.resources[1].cachedPageInfo = { hasPreviousPage: true };
      paginator.resources[2].cachedPageInfo = { hasPreviousPage: false };

      expect(paginator.hasPreviousPage()).toBe(true);
    });

    it('returns false when no resources have previous page', () => {
      paginator.resources[0].cachedPageInfo = { hasPreviousPage: false };
      paginator.resources[1].cachedPageInfo = { hasPreviousPage: false };
      paginator.resources[2].cachedPageInfo = { hasPreviousPage: false };

      expect(paginator.hasPreviousPage()).toBe(false);
    });

    it('returns false when no resources have cached pageInfo', () => {
      expect(paginator.hasPreviousPage()).toBe(false);
    });

    it('handles partial cached pageInfo', () => {
      paginator.resources[0].cachedPageInfo = { hasPreviousPage: false };
      paginator.resources[2].cachedPageInfo = { hasPreviousPage: true };

      expect(paginator.hasPreviousPage()).toBe(true);
    });
  });

  describe('skip functionality', () => {
    beforeEach(() => {
      mockResources = [
        createMockResource({ skip: () => false }),
        createMockResource({ skip: () => true }),
        createMockResource({ skip: () => false }),
      ];
      paginator = new SequentialCursorPaginator(mockApollo, mockResources, 5);
    });

    it('skips resources when skip function returns true in getNextCombinedPage', async () => {
      // Mock for main query (resource 0)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }, { id: 2 }], {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'end1',
          startCursor: 'start1',
        }),
      );
      // Mock for main query (resource 2, skipping resource 1)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 3 }, { id: 4 }, { id: 5 }], {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'end3',
          startCursor: 'start3',
        }),
      );

      const result = await paginator.getNextCombinedPage({ projectId: '123' });

      expect(mockApollo.query).toHaveBeenCalledTimes(2);
      expect(result).toEqual([{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }]);
    });

    it('skips resources when skip function returns true in getPreviousCombinedPage', async () => {
      paginator.resourceStartIndex = 2;
      paginator.resources[2].cachedPageInfo = {
        hasPreviousPage: true,
        startCursor: 'start3',
      };

      // Mock for main query (resource 2)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 3 }, { id: 4 }, { id: 5 }], {
          hasNextPage: false,
          hasPreviousPage: true,
          endCursor: 'end3',
          startCursor: 'start3',
        }),
      );
      // Mock for main query (resource 0, skipping resource 1)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }, { id: 2 }], {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'end1',
          startCursor: 'start1',
        }),
      );

      const result = await paginator.getPreviousCombinedPage({ projectId: '123' });

      expect(mockApollo.query).toHaveBeenCalledTimes(2);
      expect(result).toEqual([{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }]);
    });

    it('skips resources in checkIfAdjacentResourceHasMorePages', async () => {
      await paginator.checkIfAdjacentResourceHasMorePages('NEXT', 1, { projectId: '123' });

      expect(mockApollo.query).not.toHaveBeenCalled();
    });

    it('does not skip resources when skip function returns false', async () => {
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([], {
          hasNextPage: true,
          hasPreviousPage: false,
          endCursor: null,
          startCursor: null,
        }),
      );

      await paginator.checkIfAdjacentResourceHasMorePages('NEXT', 0, { projectId: '123' });

      expect(mockApollo.query).toHaveBeenCalledTimes(1);
    });

    it('ignores skipped resources in hasNextPage', () => {
      paginator.resources[0].cachedPageInfo = { hasNextPage: false };
      paginator.resources[1].cachedPageInfo = { hasNextPage: true }; // This is skipped
      paginator.resources[2].cachedPageInfo = { hasNextPage: false };

      expect(paginator.hasNextPage()).toBe(false);
    });

    it('ignores skipped resources in hasPreviousPage', () => {
      paginator.resources[0].cachedPageInfo = { hasPreviousPage: false };
      paginator.resources[1].cachedPageInfo = { hasPreviousPage: true }; // This is skipped
      paginator.resources[2].cachedPageInfo = { hasPreviousPage: false };

      expect(paginator.hasPreviousPage()).toBe(false);
    });

    it('handles dynamic skip conditions', async () => {
      let shouldSkipResource1 = false;
      mockResources = [
        createMockResource({ skip: () => false }),
        createMockResource({ skip: () => shouldSkipResource1 }),
        createMockResource({ skip: () => false }),
      ];
      paginator = new SequentialCursorPaginator(mockApollo, mockResources, 5);

      // First call - resource 1 is not skipped
      // Mock for main query (resource 0)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }, { id: 2 }], {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'end1',
          startCursor: 'start1',
        }),
      );
      // Mock for main query (resource 1)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 3 }, { id: 4 }, { id: 5 }], {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'end2',
          startCursor: 'start2',
        }),
      );
      // Mock for checkIfAnyResourceHasMorePages (resource 2)
      mockEmptyMetadataQueries(1);

      let result = await paginator.getNextCombinedPage({ projectId: '123' });

      expect(mockApollo.query).toHaveBeenCalledTimes(3);
      expect(result).toEqual([{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }]);

      // Reset for second call
      mockApollo.query.mockClear();
      paginator.resourceStartIndex = 0;
      paginator.resourceEndIndex = 0;

      // Second call - resource 1 is now skipped
      shouldSkipResource1 = true;
      // Mock for main query (resource 0)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 1 }, { id: 2 }], {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'end1',
          startCursor: 'start1',
        }),
      );
      // Mock for main query (resource 2, skipping resource 1)
      mockApollo.query.mockResolvedValueOnce(
        createMockQueryResult([{ id: 6 }, { id: 7 }, { id: 8 }], {
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: 'end3',
          startCursor: 'start3',
        }),
      );

      result = await paginator.getNextCombinedPage({ projectId: '123' });

      expect(mockApollo.query).toHaveBeenCalledTimes(2);
      expect(result).toEqual([{ id: 1 }, { id: 2 }, { id: 6 }, { id: 7 }, { id: 8 }]);
    });
  });
});
