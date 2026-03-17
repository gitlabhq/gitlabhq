import { InMemoryCache } from '@apollo/client/core';
import { removeClientSetsFromDocument } from '@apollo/client/utilities';
import { createMockClient as createMockApolloClient } from 'mock-apollo-client';
import { cloneDeep } from 'lodash';
import { print, Kind } from 'graphql';
import VueApollo from 'vue-apollo';
import possibleTypes from '~/graphql_shared/possible_types.json';
import { typePolicies } from '~/lib/graphql';
import waitForPromises from 'helpers/wait_for_promises';

const RESOLVE_ALL_MAX_DEPTH = 50;

const getOperationType = (doc) => {
  const definition = doc.definitions.find((def) => def.kind === Kind.OPERATION_DEFINITION);
  return definition ? definition.operation : null;
};

const assertOperationType = (doc, expected) => {
  const actual = getOperationType(doc);
  if (actual !== expected) {
    throw new Error(
      `Expected a ${expected} document but received a ${actual || 'unknown'} operation`,
    );
  }
};

/**
 * Creates a mock Apollo client with controlled resolution support
 */
export function createMockClient(
  handlers = [],
  resolvers = {},
  { legacyMode = true, ...cacheOptions } = {},
) {
  if (!Array.isArray(handlers)) {
    throw new Error('You should pass an array of handlers to mock Apollo client');
  }

  const cache = new InMemoryCache({
    possibleTypes,
    typePolicies,
    ...cacheOptions,
  });

  const mockClient = createMockApolloClient({
    cache,
    resolvers,
    queryDeduplication: legacyMode,
  });

  // Save original before createLegacyMockApollo can overwrite it
  const originalSetRequestHandler = mockClient.setRequestHandler.bind(mockClient);

  // State for controlled resolution
  const pendingOperations = new Map(); // query string -> [{resolve, reject, response}]
  const handlerState = new Map(); // query string -> handler

  const getQueryKey = (query) => {
    const stripped = removeClientSetsFromDocument(query);
    return print(stripped || query);
  };

  const assertControlledMode = (methodName) => {
    if (legacyMode) {
      throw new Error(
        `${methodName}() is not available in legacy mode. ` +
          'Use the named export createControlledMockApollo() for controlled resolution.',
      );
    }
  };

  const registerHandler = (query, handler) => {
    const stripped = removeClientSetsFromDocument(query);
    if (stripped === null) {
      // eslint-disable-next-line no-console
      console.warn(
        'MockLink: query is entirely client-side (@client directives only), skipping handler registration.',
      );
      return;
    }

    const key = getQueryKey(query);

    if (handlerState.has(key)) {
      throw new Error(`Request handler already defined for query: ${print(stripped)}`);
    } else {
      handlerState.set(key, handler);

      originalSetRequestHandler(stripped, (variables) => {
        const currentHandler = handlerState.get(key);

        if (!currentHandler) {
          throw new Error(`Request handler not defined for query: ${print(stripped)}`);
        }

        const response =
          legacyMode || typeof currentHandler === 'function'
            ? currentHandler(variables)
            : currentHandler;

        // Subscriptions - pass through
        if (response && typeof response.subscribe === 'function') {
          return response;
        }

        if (legacyMode) {
          // Legacy mode: resolve immediately with deep clone
          return Promise.resolve(response).then((r) => cloneDeep(r ?? {}));
        }

        // Controlled mode: create deferred promise
        let resolveDeferred;
        let rejectDeferred;
        const deferred = new Promise((resolve, reject) => {
          resolveDeferred = resolve;
          rejectDeferred = reject;
        });

        const pending = pendingOperations.get(key) || [];
        pending.push({ resolve: resolveDeferred, reject: rejectDeferred, response });
        pendingOperations.set(key, pending);

        return deferred;
      });
    }
  };

  // Register initial handlers
  handlers.forEach(([query, handler]) => registerHandler(query, handler));

  const shiftPending = (queryDoc) => {
    const key = getQueryKey(queryDoc);
    const pending = pendingOperations.get(key);
    if (!pending || pending.length === 0) return null;
    const entry = pending.shift();
    if (pending.length === 0) pendingOperations.delete(key);
    return entry;
  };

  const resolveEntry = (entry, overrideData) =>
    entry.resolve(overrideData !== undefined ? overrideData : entry.response);

  const createTypedMethod = (methodName, operationType, settle) => (doc, arg) => {
    assertControlledMode(methodName);
    assertOperationType(doc, operationType);
    const entry = shiftPending(doc);
    if (entry) settle(entry, arg);
    return waitForPromises();
  };

  const resolveQuery = createTypedMethod('resolveQuery', 'query', resolveEntry);
  const resolveMutation = createTypedMethod('resolveMutation', 'mutation', resolveEntry);
  const rejectQuery = createTypedMethod('rejectQuery', 'query', (entry, error) =>
    entry.reject(error),
  );
  const rejectMutation = createTypedMethod('rejectMutation', 'mutation', (entry, error) =>
    entry.reject(error),
  );

  const resolveAll = (_isRecursiveCall = false, _depth = 0) => {
    assertControlledMode('resolveAll');

    if (!_isRecursiveCall && pendingOperations.size === 0) {
      throw new Error(
        'resolveAll: no pending queries/mutations to resolve. ' +
          'Do not use resolveAll() as a substitute for waitForPromises().',
      );
    }

    if (_depth >= RESOLVE_ALL_MAX_DEPTH) {
      throw new Error(
        `resolveAll() exceeded maximum recursion depth (${RESOLVE_ALL_MAX_DEPTH}). ` +
          'This usually means a resolved query triggers the same query again in an infinite loop.',
      );
    }

    pendingOperations.forEach((entries) => {
      entries.forEach((entry) => entry.resolve(entry.response));
    });
    pendingOperations.clear();

    return waitForPromises().then(() => {
      if (pendingOperations.size > 0) {
        return resolveAll(true, _depth + 1);
      }
      return undefined;
    });
  };

  const result = {
    client: mockClient,
    resolveQuery,
    resolveMutation,
    rejectQuery,
    rejectMutation,
    resolveAll,
  };

  if (legacyMode) {
    return mockClient;
  }

  return result;
}

export function createControlledMockApollo(handlers, resolvers, cacheOptions) {
  const mockClientResult = createMockClient(handlers, resolvers, {
    legacyMode: false,
    ...cacheOptions,
  });
  const apolloProvider = new VueApollo({ defaultClient: mockClientResult.client });

  return {
    apolloProvider,
    ...mockClientResult,
  };
}

export function createLegacyMockApollo(handlers, resolvers, cacheOptions) {
  const mockClient = createMockClient(handlers, resolvers, {
    legacyMode: true,
    ...cacheOptions,
  });
  return new VueApollo({ defaultClient: mockClient });
}

export default createLegacyMockApollo;
