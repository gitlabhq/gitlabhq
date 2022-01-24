import { InMemoryCache } from 'apollo-cache-inmemory';
import { createMockClient as createMockApolloClient } from 'mock-apollo-client';
import VueApollo from 'vue-apollo';

const defaultCacheOptions = {
  fragmentMatcher: { match: () => true },
  addTypename: false,
};

export function createMockClient(handlers = [], resolvers = {}, cacheOptions = {}) {
  const cache = new InMemoryCache({
    ...defaultCacheOptions,
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
