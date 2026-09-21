import { createCache } from '~/lib/graphql';
import { config } from '~/graphql_shared/issuable_client';

/**
 * An InMemoryCache built the way the issuable client builds its own. `config.cacheConfig`
 * carries neither the global type policies nor possibleTypes, and without possibleTypes the
 * `... on WorkItemWidgetX` inline fragments never match.
 */
export const createIssuableCache = () => createCache(config.cacheConfig);

/**
 * Asserts the cache can fully satisfy `query` with `variables`.
 *
 * A write that does not cover the selection set only logs "Missing field 'x' while
 * writing result", so the cache looks fine until a component reads it and misses.
 * Diffing the document back out turns that into an assertion failure naming the field.
 */
export const expectCacheHit = (cache, { query, variables }) => {
  const { complete, missing } = cache.diff({
    query,
    variables,
    optimistic: false,
    returnPartialData: true,
  });

  expect((missing ?? []).map(({ message }) => message)).toEqual([]);
  expect(complete).toBe(true);
};
