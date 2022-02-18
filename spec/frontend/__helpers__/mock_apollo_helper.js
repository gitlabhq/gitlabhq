import { InMemoryCache } from '@apollo/client/core';
import { createMockClient as createMockApolloClient } from 'mock-apollo-client';
import VueApollo from 'vue-apollo';
import possibleTypes from '~/graphql_shared/possibleTypes.json';
import { typePolicies } from '~/lib/graphql';

export function createMockClient(handlers = [], resolvers = {}, cacheOptions = {}) {
  const cache = new InMemoryCache({
    possibleTypes,
    typePolicies,
    addTypename: false,
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

export default function createMockApollo(handlers, resolvers, cacheOptions) {
  const mockClient = createMockClient(handlers, resolvers, cacheOptions);
  return new VueApollo({ defaultClient: mockClient });
}
