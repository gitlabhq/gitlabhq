import { InMemoryCache } from 'apollo-cache-inmemory';
import { createMockClient } from 'mock-apollo-client';
import VueApollo from 'vue-apollo';

export default (handlers = [], resolvers = {}) => {
  const fragmentMatcher = { match: () => true };
  const cache = new InMemoryCache({
    fragmentMatcher,
    addTypename: false,
  });

  const mockClient = createMockClient({ cache, resolvers });

  if (Array.isArray(handlers)) {
    handlers.forEach(([query, value]) => mockClient.setRequestHandler(query, value));
  } else {
    throw new Error('You should pass an array of handlers to mock Apollo client');
  }

  const apolloProvider = new VueApollo({ defaultClient: mockClient });

  return apolloProvider;
};
