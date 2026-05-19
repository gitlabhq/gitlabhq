import { fetchPolicies } from '~/lib/graphql';

const DIRECTION = {
  NEXT: 'NEXT',
  PREVIOUS: 'PREVIOUS',
};
const DEFAULT_PAGE_SIZE = 20;
const METADATA_ONLY_PAGE_SIZE = 1;

const buildPaginationVariables = ({ resource, itemsNeeded, cursor, direction }) => {
  const { first, after, last, before } = resource;

  if (direction === DIRECTION.NEXT) {
    return {
      [first]: itemsNeeded,
      [after]: cursor,
    };
  }

  return {
    [last]: itemsNeeded,
    [before]: cursor,
  };
};

/**
 * @typedef {Object} PaginationResource
 * @property {Object} query - The GraphQL query to fetch this resource
 * @property {Function} [skip] - Optional function that returns true to skip this resource during pagination
 * @property {string} first - The GraphQL variable name for forward pagination limit (e.g., 'first')
 * @property {string} after - The GraphQL variable name for forward pagination cursor (e.g., 'after')
 * @property {string} last - The GraphQL variable name for backward pagination limit (e.g., 'last')
 * @property {string} before - The GraphQL variable name for backward pagination cursor (e.g., 'before')
 * @property {Function} getNodes - Function that extracts items array from the query result
 * @property {Function} getPageInfo - Function that extracts pageInfo object from the query result
 * @property {Object} [baseVariables] - Optional additional GraphQL variables to include in every query
 * @property {Object} [cachedPageInfo] - Cached pagination metadata (hasNextPage, hasPreviousPage, endCursor, startCursor)
 * @property {Number} [timeout] - Optional request timeout (milliseconds), rejects with an error if the request takes longer
 */

export default class SequentialCursorPaginator {
  /**
   * Create a new sequential cursor-based paginator
   * @param {Object} $apollo - Component's $apollo object, used for queries
   * @param {Array<PaginationResource>} resources - the resources to combine sequentially, in display order
   * @param {Number} pageSize - Size of pages to return
   */
  constructor($apollo, resources, pageSize = DEFAULT_PAGE_SIZE) {
    this.$apollo = $apollo;
    this.resources = resources;
    this.pageSize = pageSize;

    // The index of the resource that the first item on the current page is from
    this.resourceStartIndex = 0;

    // The index of the resource that the last item on the current page is from
    this.resourceEndIndex = 0;

    // The cursor pointing to the item before the current page starts
    // used for refetching the current page
    this.beforePageCursor = null;
  }

  reset(variables) {
    // Reset pagination state
    this.resourceStartIndex = 0;
    this.resourceEndIndex = 0;
    this.beforePageCursor = null;
    this.resources.forEach(
      (_, resourceIndex) => delete this.resources[resourceIndex].cachedPageInfo,
    );

    // Return initial page
    return this.getNextCombinedPage(variables);
  }

  /**
   * Send a new request with the same variables to get updated data for the current page
   * @param {Object} componentVariables - Query variables from the component (for example: a search string or filters)
   * @returns {Promise<Array<Object>>} Resolves with the updated data for items on the current page
   */
  refetch(componentVariables) {
    if (!this.beforePageCursor) {
      // First page, no cursor needed
      return this.reset(componentVariables);
    }

    // Set up to fetch forward from the cursor before the page
    const startResource = this.resources[this.resourceStartIndex];
    this.resourceEndIndex = this.resourceStartIndex;
    startResource.cachedPageInfo = {
      hasNextPage: true,
      endCursor: this.beforePageCursor,
    };

    return this.getNextCombinedPage(componentVariables);
  }

  async getPageFromResource(resource, index, variables) {
    const { query, baseVariables = {}, getNodes, getPageInfo, timeout } = resource;
    const queryPromise = this.$apollo.query({
      query,
      variables: { ...baseVariables, ...variables },
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
    });
    const result = await (timeout
      ? Promise.race([
          queryPromise,
          new Promise((_resolve, reject) => {
            setTimeout(() => reject(new Error(`Request timed out after ${timeout}ms`)), timeout);
          }),
        ])
      : queryPromise);
    this.resources[index].cachedPageInfo = getPageInfo(result);
    return getNodes(result);
  }

  async getNextCombinedPage(componentVariables) {
    let combinedPageItems = [];

    // Store the current end cursor as the "before page" cursor for the next page
    const currentEndResource = this.resources[this.resourceEndIndex];
    this.beforePageCursor = currentEndResource?.cachedPageInfo?.endCursor || null;

    // This page starts on the resource that the last page ended on
    this.resourceStartIndex = this.resourceEndIndex;
    let resourceIndex = this.resourceStartIndex;

    // Check pageInfo for previous resources
    // to reset stale cursors
    await this.checkIfAnyResourceHasMorePages(
      DIRECTION.PREVIOUS,
      this.resourceStartIndex - 1,
      componentVariables,
    );

    // Iterate forward through resources to fill the page in the "next" direction
    while (combinedPageItems.length < this.pageSize && resourceIndex < this.resources.length) {
      const resource = this.resources[resourceIndex];

      // Skip this resource if skip function returns true
      if (!resource.skip?.()) {
        const itemsNeeded = this.pageSize - combinedPageItems.length;
        const cursor = resource.cachedPageInfo?.endCursor || null;

        const paginationVariables = buildPaginationVariables({
          resource,
          itemsNeeded,
          cursor,
          direction: DIRECTION.NEXT,
        });
        // eslint-disable-next-line no-await-in-loop
        const pageFromResource = await this.getPageFromResource(resource, resourceIndex, {
          ...componentVariables,
          ...paginationVariables,
        });

        combinedPageItems = [...combinedPageItems, ...pageFromResource];
        this.resourceEndIndex = resourceIndex;
      }
      resourceIndex += 1;
    }

    // Check pageInfo for next resource
    // to correctly set hasNextPage
    await this.checkIfAnyResourceHasMorePages(
      DIRECTION.NEXT,
      this.resourceEndIndex + 1,
      componentVariables,
    );

    return combinedPageItems;
  }

  async getPreviousCombinedPage(componentVariables) {
    let combinedPageItems = [];

    // Store the current start cursor as the "before page" cursor for the previous page
    const currentStartResource = this.resources[this.resourceStartIndex];
    this.beforePageCursor = currentStartResource?.cachedPageInfo?.startCursor || null;

    // This page ends on the resource that the last page started on
    this.resourceEndIndex = this.resourceStartIndex;
    let resourceIndex = this.resourceEndIndex;

    // Check pageInfo for next resources
    // to reset stale cursors
    await this.checkIfAnyResourceHasMorePages(
      DIRECTION.NEXT,
      this.resourceEndIndex + 1,
      componentVariables,
    );

    // Iterate backward through resources to fill the page in the "previous" direction
    while (combinedPageItems.length < this.pageSize && resourceIndex >= 0) {
      const resource = this.resources[resourceIndex];

      // Skip this resource if skip function returns true
      if (!resource.skip?.()) {
        const itemsNeeded = this.pageSize - combinedPageItems.length;
        const cursor = resource.cachedPageInfo?.startCursor || null;

        const paginationVariables = buildPaginationVariables({
          resource,
          itemsNeeded,
          cursor,
          direction: DIRECTION.PREVIOUS,
        });
        // eslint-disable-next-line no-await-in-loop
        const pageFromResource = await this.getPageFromResource(resource, resourceIndex, {
          ...componentVariables,
          ...paginationVariables,
        });

        combinedPageItems = [...pageFromResource, ...combinedPageItems];
        this.resourceStartIndex = resourceIndex;
      }
      resourceIndex -= 1;
    }

    // Check pageInfo for previous resource
    // to correctly set hasPreviousPage
    await this.checkIfAnyResourceHasMorePages(
      DIRECTION.PREVIOUS,
      this.resourceStartIndex - 1,
      componentVariables,
    );

    return combinedPageItems;
  }

  async checkIfAdjacentResourceHasMorePages(direction, resourceIndex, componentVariables) {
    const resource = this.resources[resourceIndex];
    if (!resource) return;

    // Skip this resource if skip function returns true
    if (resource.skip?.()) return;

    // Fetch one item to get hasNextPage/hasPreviousPage without loading much data
    const paginationVariables = buildPaginationVariables({
      resource,
      itemsNeeded: METADATA_ONLY_PAGE_SIZE,
      cursor: null,
      direction,
    });

    await this.getPageFromResource(resource, resourceIndex, {
      ...componentVariables,
      ...paginationVariables,
    });
  }
  async checkIfAnyResourceHasMorePages(direction, resourceIndex, componentVariables) {
    const resourcesToCheck = [];
    if (direction === DIRECTION.NEXT) {
      // Check all resources from resourceIndex onwards
      for (let i = resourceIndex; i < this.resources.length; i += 1) resourcesToCheck.push(i);
    } else {
      // Check all resources from resourceIndex backwards
      for (let i = resourceIndex; i >= 0; i -= 1) resourcesToCheck.push(i);
    }
    await Promise.all(
      resourcesToCheck.map((i) =>
        this.checkIfAdjacentResourceHasMorePages(direction, i, componentVariables),
      ),
    );
  }

  hasNextPage() {
    return this.resources.some(
      (resource) => !resource.skip?.() && resource.cachedPageInfo?.hasNextPage,
    );
  }

  hasPreviousPage() {
    return this.resources.some(
      (resource) => !resource.skip?.() && resource.cachedPageInfo?.hasPreviousPage,
    );
  }
}
