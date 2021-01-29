import MockAdapter from 'axios-mock-adapter';
import { InMemoryCache } from 'apollo-cache-inmemory';
import { createMockClient } from 'mock-apollo-client';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import {
  clientTypenames,
  createResolvers,
} from '~/import_entities/import_groups/graphql/client_factory';
import { StatusPoller } from '~/import_entities/import_groups/graphql/services/status_poller';
import { STATUSES } from '~/import_entities/constants';

import bulkImportSourceGroupsQuery from '~/import_entities/import_groups/graphql/queries/bulk_import_source_groups.query.graphql';
import availableNamespacesQuery from '~/import_entities/import_groups/graphql/queries/available_namespaces.query.graphql';
import setTargetNamespaceMutation from '~/import_entities/import_groups/graphql/mutations/set_target_namespace.mutation.graphql';
import setNewNameMutation from '~/import_entities/import_groups/graphql/mutations/set_new_name.mutation.graphql';
import importGroupMutation from '~/import_entities/import_groups/graphql/mutations/import_group.mutation.graphql';
import httpStatus from '~/lib/utils/http_status';
import { statusEndpointFixture, availableNamespacesFixture } from './fixtures';

jest.mock('~/import_entities/import_groups/graphql/services/status_poller', () => ({
  StatusPoller: jest.fn().mockImplementation(function mock() {
    this.startPolling = jest.fn();
  }),
}));

const FAKE_ENDPOINTS = {
  status: '/fake_status_url',
  availableNamespaces: '/fake_available_namespaces',
  createBulkImport: '/fake_create_bulk_import',
};

describe('Bulk import resolvers', () => {
  let axiosMockAdapter;
  let client;

  beforeEach(() => {
    axiosMockAdapter = new MockAdapter(axios);
    client = createMockClient({
      cache: new InMemoryCache({
        fragmentMatcher: { match: () => true },
        addTypename: false,
      }),
      resolvers: createResolvers({ endpoints: FAKE_ENDPOINTS }),
    });
  });

  afterEach(() => {
    axiosMockAdapter.restore();
  });

  describe('queries', () => {
    describe('availableNamespaces', () => {
      let results;

      beforeEach(async () => {
        axiosMockAdapter
          .onGet(FAKE_ENDPOINTS.availableNamespaces)
          .reply(httpStatus.OK, availableNamespacesFixture);

        const response = await client.query({ query: availableNamespacesQuery });
        results = response.data.availableNamespaces;
      });

      it('mirrors REST endpoint response fields', () => {
        const extractRelevantFields = (obj) => ({ id: obj.id, full_path: obj.full_path });

        expect(results.map(extractRelevantFields)).toStrictEqual(
          availableNamespacesFixture.map(extractRelevantFields),
        );
      });
    });

    describe('bulkImportSourceGroups', () => {
      let results;

      beforeEach(async () => {
        axiosMockAdapter.onGet(FAKE_ENDPOINTS.status).reply(httpStatus.OK, statusEndpointFixture);
        axiosMockAdapter
          .onGet(FAKE_ENDPOINTS.availableNamespaces)
          .reply(httpStatus.OK, availableNamespacesFixture);
      });

      describe('when called', () => {
        beforeEach(async () => {
          const response = await client.query({ query: bulkImportSourceGroupsQuery });
          results = response.data.bulkImportSourceGroups.nodes;
        });

        it('mirrors REST endpoint response fields', () => {
          const MIRRORED_FIELDS = ['id', 'full_name', 'full_path', 'web_url'];
          expect(
            results.every((r, idx) =>
              MIRRORED_FIELDS.every(
                (field) => r[field] === statusEndpointFixture.importable_data[idx][field],
              ),
            ),
          ).toBe(true);
        });

        it('populates each result instance with status field default to none', () => {
          expect(results.every((r) => r.status === STATUSES.NONE)).toBe(true);
        });

        it('populates each result instance with import_target defaulted to first available namespace', () => {
          expect(
            results.every(
              (r) => r.import_target.target_namespace === availableNamespacesFixture[0].full_path,
            ),
          ).toBe(true);
        });
      });

      it.each`
        variable     | queryParam    | value
        ${'filter'}  | ${'filter'}   | ${'demo'}
        ${'perPage'} | ${'per_page'} | ${30}
        ${'page'}    | ${'page'}     | ${3}
      `(
        'properly passes GraphQL variable $variable as REST $queryParam query parameter',
        async ({ variable, queryParam, value }) => {
          await client.query({
            query: bulkImportSourceGroupsQuery,
            variables: { [variable]: value },
          });
          const restCall = axiosMockAdapter.history.get.find(
            (q) => q.url === FAKE_ENDPOINTS.status,
          );
          expect(restCall.params[queryParam]).toBe(value);
        },
      );
    });
  });

  describe('mutations', () => {
    let results;
    const GROUP_ID = 1;

    beforeEach(() => {
      client.writeQuery({
        query: bulkImportSourceGroupsQuery,
        data: {
          bulkImportSourceGroups: {
            nodes: [
              {
                __typename: clientTypenames.BulkImportSourceGroup,
                id: GROUP_ID,
                status: STATUSES.NONE,
                web_url: 'https://fake.host/1',
                full_path: 'fake_group_1',
                full_name: 'fake_name_1',
                import_target: {
                  target_namespace: 'root',
                  new_name: 'group1',
                },
              },
            ],
            pageInfo: {
              page: 1,
              perPage: 20,
              total: 37,
              totalPages: 2,
            },
          },
        },
      });

      client
        .watchQuery({
          query: bulkImportSourceGroupsQuery,
          fetchPolicy: 'cache-only',
        })
        .subscribe(({ data }) => {
          results = data.bulkImportSourceGroups.nodes;
        });
    });

    it('setTargetNamespaces updates group target namespace', async () => {
      const NEW_TARGET_NAMESPACE = 'target';
      await client.mutate({
        mutation: setTargetNamespaceMutation,
        variables: { sourceGroupId: GROUP_ID, targetNamespace: NEW_TARGET_NAMESPACE },
      });

      expect(results[0].import_target.target_namespace).toBe(NEW_TARGET_NAMESPACE);
    });

    it('setNewName updates group target name', async () => {
      const NEW_NAME = 'new';
      await client.mutate({
        mutation: setNewNameMutation,
        variables: { sourceGroupId: GROUP_ID, newName: NEW_NAME },
      });

      expect(results[0].import_target.new_name).toBe(NEW_NAME);
    });

    describe('importGroup', () => {
      it('sets status to SCHEDULING when request initiates', async () => {
        axiosMockAdapter.onPost(FAKE_ENDPOINTS.createBulkImport).reply(() => new Promise(() => {}));

        client.mutate({
          mutation: importGroupMutation,
          variables: { sourceGroupId: GROUP_ID },
        });
        await waitForPromises();

        const {
          bulkImportSourceGroups: { nodes: intermediateResults },
        } = client.readQuery({
          query: bulkImportSourceGroupsQuery,
        });

        expect(intermediateResults[0].status).toBe(STATUSES.SCHEDULING);
      });

      it('sets group status to STARTED when request completes', async () => {
        axiosMockAdapter.onPost(FAKE_ENDPOINTS.createBulkImport).reply(httpStatus.OK);
        await client.mutate({
          mutation: importGroupMutation,
          variables: { sourceGroupId: GROUP_ID },
        });

        expect(results[0].status).toBe(STATUSES.STARTED);
      });

      it('starts polling when request completes', async () => {
        axiosMockAdapter.onPost(FAKE_ENDPOINTS.createBulkImport).reply(httpStatus.OK);
        await client.mutate({
          mutation: importGroupMutation,
          variables: { sourceGroupId: GROUP_ID },
        });
        const [statusPoller] = StatusPoller.mock.instances;
        expect(statusPoller.startPolling).toHaveBeenCalled();
      });

      it('resets status to NONE if request fails', async () => {
        axiosMockAdapter
          .onPost(FAKE_ENDPOINTS.createBulkImport)
          .reply(httpStatus.INTERNAL_SERVER_ERROR);

        client
          .mutate({
            mutation: importGroupMutation,
            variables: { sourceGroupId: GROUP_ID },
          })
          .catch(() => {});
        await waitForPromises();

        expect(results[0].status).toBe(STATUSES.NONE);
      });
    });
  });
});
