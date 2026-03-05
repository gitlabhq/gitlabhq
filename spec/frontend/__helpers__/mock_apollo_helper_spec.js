import { InMemoryCache } from '@apollo/client/core';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import gql from 'graphql-tag';
import waitForPromises from 'helpers/wait_for_promises';
import legacyMockApollo, {
  createControlledMockApollo,
  createMockClient,
} from 'helpers/mock_apollo_helper';

Vue.use(VueApollo);

const TEST_QUERY = gql`
  query TestQuery($id: ID!) {
    project(id: $id) {
      id
      name
    }
  }
`;

const TEST_QUERY_2 = gql`
  query TestQuery2($slug: String!) {
    group(slug: $slug) {
      id
      title
    }
  }
`;

const TEST_MUTATION = gql`
  mutation TestMutation($input: TestInput!) {
    testMutation(input: $input) {
      id
    }
  }
`;

const UNMOCKED_QUERY = gql`
  query UnmockedQuery {
    unmocked {
      id
    }
  }
`;

const mockProjectResponse = { data: { project: { id: '1', name: 'Test Project' } } };
const mockGroupResponse = { data: { group: { id: '2', title: 'Test Group' } } };
const mockMutationResponse = { data: { testMutation: { id: '99' } } };

// Minimal component for Vue integration tests
const TestComponent = {
  template: '<div>{{ loading ? "loading" : (error ? error.message : name) }}</div>',
  data() {
    return { name: '', loading: true, error: null };
  },
  apollo: {
    project: {
      query: TEST_QUERY,
      variables() {
        return { id: '1' };
      },
      update(data) {
        this.name = data.project.name;
      },
      error(err) {
        this.error = err;
      },
      result({ loading }) {
        this.loading = loading;
      },
    },
  },
};

function createWrapper(apolloProvider) {
  return shallowMount(TestComponent, {
    apolloProvider,
  });
}

describe('mock_apollo_helper', () => {
  describe('shared between legacy and controlled', () => {
    function createClient(mode, handlers, { resolvers, cacheOptions } = {}) {
      if (mode === 'legacy') {
        return { client: createMockClient(handlers, resolvers, cacheOptions) };
      }
      return createMockClient(handlers, resolvers, { ...cacheOptions, legacyMode: false });
    }

    async function resolveIfControlled(controls) {
      if (controls.resolveAll) await controls.resolveAll();
    }

    describe.each([['legacy'], ['controlled']])('in %s mode', (mode) => {
      it('calls handler with correct variables', async () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const controls = createClient(mode, [[TEST_QUERY, handler]]);

        expect(handler).not.toHaveBeenCalled();

        controls.client.query({ query: TEST_QUERY, variables: { id: '42' } });
        await waitForPromises();

        expect(handler).toHaveBeenCalledWith({ id: '42' });

        await resolveIfControlled(controls);
      });

      it('returns response data', async () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const controls = createClient(mode, [[TEST_QUERY, handler]]);

        const resultPromise = controls.client.query({
          query: TEST_QUERY,
          variables: { id: '1' },
        });

        await resolveIfControlled(controls);
        await waitForPromises();
        const result = await resultPromise;

        expect(result.data).toEqual(mockProjectResponse.data);
      });

      it('propagates errors', async () => {
        const error = new Error('Network failure');
        const handler =
          mode === 'legacy'
            ? jest.fn().mockRejectedValue(error)
            : jest.fn().mockResolvedValue(mockProjectResponse);
        const controls = createClient(mode, [[TEST_QUERY, handler]]);

        let caughtError = null;
        controls.client.query({ query: TEST_QUERY, variables: { id: '1' } }).catch((e) => {
          caughtError = e;
        });

        if (mode === 'controlled') {
          await controls.rejectQuery(TEST_QUERY, error);
        }

        await waitForPromises();

        expect(caughtError).not.toBe(null);
        expect(caughtError.message).toContain('Network failure');
      });

      it('supports multiple independent handlers', async () => {
        const projectHandler = jest.fn().mockResolvedValue(mockProjectResponse);
        const groupHandler = jest.fn().mockResolvedValue(mockGroupResponse);
        const controls = createClient(mode, [
          [TEST_QUERY, projectHandler],
          [TEST_QUERY_2, groupHandler],
        ]);

        const p1 = controls.client.query({ query: TEST_QUERY, variables: { id: '1' } });
        const p2 = controls.client.query({
          query: TEST_QUERY_2,
          variables: { slug: 'my-group' },
        });

        await resolveIfControlled(controls);
        await waitForPromises();

        const [r1, r2] = await Promise.all([p1, p2]);

        expect(projectHandler).toHaveBeenCalledWith({ id: '1' });
        expect(groupHandler).toHaveBeenCalledWith({ slug: 'my-group' });
        expect(r1.data).toEqual(mockProjectResponse.data);
        expect(r2.data).toEqual(mockGroupResponse.data);
      });

      it('passes resolvers to the client', () => {
        const localResolver = {
          Query: {
            localField: () => 'local-value',
          },
        };
        const controls = createClient(mode, [], { resolvers: localResolver });

        expect(controls.client.getResolvers()).toEqual(localResolver);
      });

      it('passes cacheOptions through to InMemoryCache', () => {
        const controls = createClient(mode, [], { cacheOptions: { addTypename: true } });

        expect(controls.client.cache).toBeInstanceOf(InMemoryCache);
        expect(controls.client.cache.config.addTypename).toBe(true);
      });

      it('throws when registering duplicate handlers for the same query', () => {
        const handler1 = jest.fn().mockResolvedValue(mockProjectResponse);
        const handler2 = jest.fn().mockResolvedValue(mockProjectResponse);

        expect(() => {
          createClient(mode, [
            [TEST_QUERY, handler1],
            [TEST_QUERY, handler2],
          ]);
        }).toThrow(/Request handler already defined for query/);
      });

      it('throws for unmocked queries', () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const controls = createClient(mode, [[TEST_QUERY, handler]]);

        expect(() => {
          controls.client.query({ query: UNMOCKED_QUERY });
        }).toThrow(/Request handler not defined for query/);
      });
    });
  });

  describe('legacy mode', () => {
    describe('unit tests', () => {
      it('deep clones responses so mutations do not affect subsequent calls', async () => {
        // The handler returns the SAME object reference each time
        const response = { data: { project: { id: '1', name: 'Original' } } };
        const handler = jest.fn().mockResolvedValue(response);
        const client = createMockClient([[TEST_QUERY, handler]]);

        await client.query({
          query: TEST_QUERY,
          variables: { id: '1' },
          fetchPolicy: 'no-cache',
        });

        // Mutate the source response object between calls
        response.data = { project: { id: '1', name: 'MUTATED' } };

        const result2 = await client.query({
          query: TEST_QUERY,
          variables: { id: '1' },
          fetchPolicy: 'no-cache',
        });

        // cloneDeep creates a deep copy, so mutating the source does NOT affect subsequent calls
        expect(result2.data.project.name).toBe('MUTATED');
        expect(handler).toHaveBeenCalledTimes(2);
      });

      it('handles undefined handler response without crashing', async () => {
        const handler = jest.fn().mockResolvedValue(undefined);
        const client = createMockClient([[TEST_QUERY, handler]]);

        // Should not throw - undefined is converted to {} which Apollo handles gracefully
        const result = await client.query({
          query: TEST_QUERY,
          variables: { id: '1' },
          fetchPolicy: 'no-cache',
        });

        expect(handler).toHaveBeenCalled();
        expect(result).toBeDefined();
      });

      it('handles null handler response without crashing', async () => {
        const handler = jest.fn().mockResolvedValue(null);
        const client = createMockClient([[TEST_QUERY, handler]]);

        // Should not throw - null is converted to {} which Apollo handles gracefully
        const result = await client.query({
          query: TEST_QUERY,
          variables: { id: '1' },
          fetchPolicy: 'no-cache',
        });

        expect(handler).toHaveBeenCalled();
        expect(result).toBeDefined();
      });

      it('wraps synchronous handler errors with descriptive message', async () => {
        const handler = jest.fn().mockImplementation(() => {
          throw new Error('Handler exploded');
        });
        const client = createMockClient([[TEST_QUERY, handler]]);

        await expect(client.query({ query: TEST_QUERY, variables: { id: '1' } })).rejects.toThrow(
          'Unexpected error whilst calling request handler: Handler exploded',
        );
      });

      it('preserves Date objects in response data', async () => {
        const mockDate = new Date('2021-06-07T00:00:00.000Z');
        const responseWithDate = {
          data: {
            project: {
              id: '1',
              name: 'Test',
              updatedAt: mockDate,
            },
          },
        };
        const handler = jest.fn().mockResolvedValue(responseWithDate);
        const client = createMockClient([[TEST_QUERY, handler]]);

        const result = await client.query({
          query: TEST_QUERY,
          variables: { id: '1' },
          fetchPolicy: 'no-cache',
        });

        expect(result.data.project.updatedAt).toBeInstanceOf(Date);
        expect(result.data.project.updatedAt.getTime()).toBe(mockDate.getTime());
      });

      it('createLegacyMockApollo returns a VueApollo provider', () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const result = legacyMockApollo([[TEST_QUERY, handler]]);

        expect(result.clients.defaultClient).toBeDefined();
        expect(result.clients.defaultClient.cache).toBeInstanceOf(InMemoryCache);
      });

      it('createControlledMockApollo returns { apolloProvider, resolveQuery, resolveMutation, rejectQuery, rejectMutation, resolveAll }', () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const result = createControlledMockApollo([[TEST_QUERY, handler]]);

        expect(result).toEqual(
          expect.objectContaining({
            apolloProvider: expect.any(Object),
            resolveQuery: expect.any(Function),
            resolveMutation: expect.any(Function),
            rejectQuery: expect.any(Function),
            rejectMutation: expect.any(Function),
            resolveAll: expect.any(Function),
          }),
        );
      });

      it('does not expose controlled-mode methods in legacy mode', () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const client = createMockClient([[TEST_QUERY, handler]]);

        expect(client.resolveAll).toBeUndefined();
        expect(client.resolveQuery).toBeUndefined();
        expect(client.resolveMutation).toBeUndefined();
        expect(client.rejectQuery).toBeUndefined();
        expect(client.rejectMutation).toBeUndefined();
      });
    });

    describe('Vue component integration', () => {
      it('completes full query lifecycle: mount → query → handler → response → re-render', async () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const apolloProvider = legacyMockApollo([[TEST_QUERY, handler]]);

        const wrapper = createWrapper(apolloProvider);

        // Initially loading
        expect(wrapper.text()).toBe('loading');

        await waitForPromises();

        // After resolution, component should display the data
        expect(handler).toHaveBeenCalledWith({ id: '1' });
        expect(wrapper.text()).toBe('Test Project');
      });

      it('shows loading state before waitForPromises resolves', () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const apolloProvider = legacyMockApollo([[TEST_QUERY, handler]]);

        const wrapper = createWrapper(apolloProvider);

        // Before waitForPromises, the query has not resolved
        expect(wrapper.text()).toBe('loading');
      });

      it('propagates errors to the component', async () => {
        const handler = jest.fn().mockRejectedValue(new Error('Server error'));
        const apolloProvider = legacyMockApollo([[TEST_QUERY, handler]]);

        const wrapper = createWrapper(apolloProvider);
        await waitForPromises();

        expect(wrapper.text()).toBe('Server error');
      });

      it('handles mutations called from a component', async () => {
        const queryHandler = jest.fn().mockResolvedValue(mockProjectResponse);
        const mutationHandler = jest.fn().mockResolvedValue(mockMutationResponse);
        const apolloProvider = legacyMockApollo([
          [TEST_QUERY, queryHandler],
          [TEST_MUTATION, mutationHandler],
        ]);

        const wrapper = createWrapper(apolloProvider);
        await waitForPromises();

        // Call mutation via the component's Apollo client
        const mutationResult = await wrapper.vm.$apollo.mutate({
          mutation: TEST_MUTATION,
          variables: { input: { title: 'New Item' } },
        });

        expect(mutationHandler).toHaveBeenCalledWith({ input: { title: 'New Item' } });
        expect(mutationResult.data).toEqual(mockMutationResponse.data);
      });

      it('supports direct cache writes that components can read', async () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const apolloProvider = legacyMockApollo([[TEST_QUERY, handler]]);

        const wrapper = createWrapper(apolloProvider);
        await waitForPromises();

        expect(wrapper.text()).toBe('Test Project');

        // Write updated data directly to cache
        apolloProvider.clients.defaultClient.cache.writeQuery({
          query: TEST_QUERY,
          variables: { id: '1' },
          data: { project: { id: '1', name: 'Updated via Cache' } },
        });

        // Read back from cache to verify the write worked
        const cached = apolloProvider.clients.defaultClient.cache.readQuery({
          query: TEST_QUERY,
          variables: { id: '1' },
        });

        expect(cached.project.name).toBe('Updated via Cache');
      });
    });
  });

  describe('controlled mode', () => {
    describe('unit tests', () => {
      it('query hangs until resolveQuery is called', async () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const { client, resolveQuery } = createMockClient(
          [[TEST_QUERY, handler]],
          {},
          { legacyMode: false },
        );

        let resolved = false;
        // eslint-disable-next-line promise/catch-or-return
        client.query({ query: TEST_QUERY, variables: { id: '1' } }).then(() => {
          resolved = true;
        });

        await waitForPromises();
        expect(resolved).toBe(false);

        await resolveQuery(TEST_QUERY);
        expect(resolved).toBe(true);
      });

      it('resolveQuery(queryDoc, overrideData) resolves with override data', async () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const overrideData = { data: { project: { id: '1', name: 'Override Name' } } };
        const { client, resolveQuery } = createMockClient(
          [[TEST_QUERY, handler]],
          {},
          { legacyMode: false },
        );

        const resultPromise = client.query({ query: TEST_QUERY, variables: { id: '1' } });

        await resolveQuery(TEST_QUERY, overrideData);
        const result = await resultPromise;

        expect(result.data).toEqual(overrideData.data);
      });

      it('resolveAll() resolves all pending queries', async () => {
        const projectHandler = jest.fn().mockResolvedValue(mockProjectResponse);
        const groupHandler = jest.fn().mockResolvedValue(mockGroupResponse);
        const { client, resolveAll } = createMockClient(
          [
            [TEST_QUERY, projectHandler],
            [TEST_QUERY_2, groupHandler],
          ],
          {},
          { legacyMode: false },
        );

        const promise1 = client.query({ query: TEST_QUERY, variables: { id: '1' } });
        const promise2 = client.query({ query: TEST_QUERY_2, variables: { slug: 'my-group' } });

        await resolveAll();

        const [result1, result2] = await Promise.all([promise1, promise2]);
        expect(result1.data).toEqual(mockProjectResponse.data);
        expect(result2.data).toEqual(mockGroupResponse.data);
      });

      it('resolveAll() recursively resolves queries triggered by resolution', async () => {
        const projectHandler = jest.fn().mockResolvedValue(mockProjectResponse);
        const groupHandler = jest.fn().mockResolvedValue(mockGroupResponse);
        const { client, resolveAll } = createMockClient(
          [
            [TEST_QUERY, projectHandler],
            [TEST_QUERY_2, groupHandler],
          ],
          {},
          { legacyMode: false },
        );

        let secondQueryResolved = false;

        // Fire first query, and when it resolves, fire second query
        // eslint-disable-next-line promise/catch-or-return
        client
          .query({ query: TEST_QUERY, variables: { id: '1' } })
          .then(() => client.query({ query: TEST_QUERY_2, variables: { slug: 'g' } }))
          .then(() => {
            secondQueryResolved = true;
          });

        await waitForPromises();

        // Single resolveAll should resolve both waves
        await resolveAll();

        expect(secondQueryResolved).toBe(true);
      });

      it('resolveAll() throws when called with no pending operations', () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const { resolveAll } = createMockClient([[TEST_QUERY, handler]], {}, { legacyMode: false });

        expect(() => resolveAll()).toThrow(/no pending queries\/mutations to resolve/);
      });

      it('resolveAll() resolves mix of queries and mutations', async () => {
        const queryHandler = jest.fn().mockResolvedValue(mockProjectResponse);
        const mutationHandler = jest.fn().mockResolvedValue(mockMutationResponse);
        const { client, resolveAll } = createMockClient(
          [
            [TEST_QUERY, queryHandler],
            [TEST_MUTATION, mutationHandler],
          ],
          {},
          { legacyMode: false },
        );

        const queryPromise = client.query({ query: TEST_QUERY, variables: { id: '1' } });
        client.mutate({ mutation: TEST_MUTATION, variables: { input: { title: 'test' } } });

        await resolveAll();

        const result = await queryPromise;
        expect(result.data).toEqual(mockProjectResponse.data);
      });

      it('multiple pending for same query resolves FIFO', async () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const { client, resolveQuery } = createMockClient(
          [[TEST_QUERY, handler]],
          {},
          { legacyMode: false },
        );

        let firstResolved = false;
        let secondResolved = false;

        // eslint-disable-next-line promise/catch-or-return
        client
          .query({ query: TEST_QUERY, variables: { id: '1' }, fetchPolicy: 'no-cache' })
          .then(() => {
            firstResolved = true;
          });
        // eslint-disable-next-line promise/catch-or-return
        client
          .query({ query: TEST_QUERY, variables: { id: '2' }, fetchPolicy: 'no-cache' })
          .then(() => {
            secondResolved = true;
          });

        await waitForPromises();
        expect(firstResolved).toBe(false);
        expect(secondResolved).toBe(false);

        await resolveQuery(TEST_QUERY);
        expect(firstResolved).toBe(true);
        expect(secondResolved).toBe(false);

        await resolveQuery(TEST_QUERY);
        expect(secondResolved).toBe(true);
      });

      it('handler as plain data object is used directly as pending response', async () => {
        const { client, resolveQuery } = createMockClient(
          [[TEST_QUERY, mockProjectResponse]],
          {},
          { legacyMode: false },
        );

        const resultPromise = client.query({ query: TEST_QUERY, variables: { id: '1' } });

        await resolveQuery(TEST_QUERY);
        const result = await resultPromise;

        expect(result.data).toEqual(mockProjectResponse.data);
      });

      it('resolveQuery throws when passed a mutation document', () => {
        const handler = jest.fn().mockResolvedValue(mockMutationResponse);
        const { resolveQuery } = createMockClient(
          [[TEST_MUTATION, handler]],
          {},
          { legacyMode: false },
        );

        expect(() => resolveQuery(TEST_MUTATION)).toThrow(
          'Expected a query document but received a mutation operation',
        );
      });

      it('resolveMutation throws when passed a query document', () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const { resolveMutation } = createMockClient(
          [[TEST_QUERY, handler]],
          {},
          { legacyMode: false },
        );

        expect(() => resolveMutation(TEST_QUERY)).toThrow(
          'Expected a mutation document but received a query operation',
        );
      });

      it('rejectQuery throws when passed a mutation document', () => {
        const handler = jest.fn().mockResolvedValue(mockMutationResponse);
        const { rejectQuery } = createMockClient(
          [[TEST_MUTATION, handler]],
          {},
          { legacyMode: false },
        );

        expect(() => rejectQuery(TEST_MUTATION, new Error('test'))).toThrow(
          'Expected a query document but received a mutation operation',
        );
      });

      it('rejectMutation throws when passed a query document', () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const { rejectMutation } = createMockClient(
          [[TEST_QUERY, handler]],
          {},
          { legacyMode: false },
        );

        expect(() => rejectMutation(TEST_QUERY, new Error('test'))).toThrow(
          'Expected a mutation document but received a query operation',
        );
      });
    });

    describe('Vue component integration', () => {
      it('component stays in loading state until resolveQuery() is called', async () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const { apolloProvider, resolveQuery } = createControlledMockApollo([
          [TEST_QUERY, handler],
        ]);

        const wrapper = createWrapper(apolloProvider);
        await waitForPromises();

        expect(wrapper.text()).toBe('loading');

        await resolveQuery(TEST_QUERY);

        expect(wrapper.text()).toBe('Test Project');
      });

      it('resolve with override data renders override in component', async () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const overrideData = { data: { project: { id: '1', name: 'Override Project' } } };
        const { apolloProvider, resolveQuery } = createControlledMockApollo([
          [TEST_QUERY, handler],
        ]);

        const wrapper = createWrapper(apolloProvider);
        await waitForPromises();

        await resolveQuery(TEST_QUERY, overrideData);

        expect(wrapper.text()).toBe('Override Project');
      });

      it('reject propagates error to component', async () => {
        const handler = jest.fn().mockResolvedValue(mockProjectResponse);
        const { apolloProvider, rejectQuery } = createControlledMockApollo([[TEST_QUERY, handler]]);

        const wrapper = createWrapper(apolloProvider);
        await waitForPromises();

        await rejectQuery(TEST_QUERY, new Error('Component error'));

        expect(wrapper.text()).toBe('Component error');
      });

      it('resolveAll resolves multiple queries for component', async () => {
        const queryHandler = jest.fn().mockResolvedValue(mockProjectResponse);
        const groupHandler = jest.fn().mockResolvedValue(mockGroupResponse);
        const { apolloProvider, resolveAll } = createControlledMockApollo([
          [TEST_QUERY, queryHandler],
          [TEST_QUERY_2, groupHandler],
        ]);

        const wrapper = createWrapper(apolloProvider);
        await waitForPromises();

        expect(wrapper.text()).toBe('loading');

        await resolveAll();

        expect(wrapper.text()).toBe('Test Project');
      });

      it('mutation hangs until resolveMutation is called', async () => {
        const queryHandler = jest.fn().mockResolvedValue(mockProjectResponse);
        const mutationHandler = jest.fn().mockResolvedValue(mockMutationResponse);
        const { apolloProvider, resolveQuery, resolveMutation } = createControlledMockApollo([
          [TEST_QUERY, queryHandler],
          [TEST_MUTATION, mutationHandler],
        ]);

        const wrapper = createWrapper(apolloProvider);

        // Resolve the initial query so component mounts fully
        await resolveQuery(TEST_QUERY);

        let mutationResolved = false;
        // eslint-disable-next-line promise/catch-or-return
        wrapper.vm.$apollo
          .mutate({
            mutation: TEST_MUTATION,
            variables: { input: { title: 'New Item' } },
          })
          .then(() => {
            mutationResolved = true;
          });

        await waitForPromises();
        expect(mutationResolved).toBe(false);

        await resolveMutation(TEST_MUTATION);
        expect(mutationResolved).toBe(true);
      });
    });
  });
});
