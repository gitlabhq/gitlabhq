import { InMemoryCache } from '@apollo/client/core';
import { createMockClient as createMockApolloClient } from 'mock-apollo-client';
import VueApollo from 'vue-apollo';
import possibleTypes from '~/graphql_shared/possible_types.json';
import { typePolicies } from '~/lib/graphql';

/**
 * Creates a mock Apollo client
 * @param {[DocumentNode, RequestHandler][]} handlers
 * @param {import('@apollo/client/core').Resolvers} resolvers
 * @param {import('@apollo/client/core').InMemoryCacheConfig} cacheOptions
 */
export function createMockClient(handlers = [], resolvers = {}, cacheOptions = {}) {
  const cache = new InMemoryCache({
    possibleTypes,
    typePolicies,
    ...cacheOptions,
  });

  const mockClient = createMockApolloClient({ cache, resolvers });

  if (Array.isArray(handlers)) {
    handlers.forEach(([query, value]) =>
      mockClient.setRequestHandler(query, (...args) =>
        Promise.resolve(value(...args)).then((r) => ({ ...r })),
      ),
    );
  } else {
    throw new Error('You should pass an array of handlers to mock Apollo client');
  }

  return mockClient;
}

/**
 * Creates a mock Apollo provider
 * @param {[DocumentNode, RequestHandler][]} handlers
 * @param {import('@apollo/client/core').Resolvers} resolvers
 * @param {import('@apollo/client/core').InMemoryCacheConfig} cacheOptions
 */
export default function createMockApollo(handlers, resolvers, cacheOptions) {
  const mockClient = createMockClient(handlers, resolvers, cacheOptions);
  return new VueApollo({ defaultClient: mockClient });
}
