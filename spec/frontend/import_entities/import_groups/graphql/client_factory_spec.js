import { InMemoryCache } from '@apollo/client/core';
import MockAdapter from 'axios-mock-adapter';
import { createMockClient } from 'mock-apollo-client';
import waitForPromises from 'helpers/wait_for_promises';
import { STATUSES } from '~/import_entities/constants';
import {
  clientTypenames,
  createResolvers,
} from '~/import_entities/import_groups/graphql/client_factory';
import { LocalStorageCache } from '~/import_entities/import_groups/graphql/services/local_storage_cache';
import importGroupsMutation from '~/import_entities/import_groups/graphql/mutations/import_groups.mutation.graphql';
import updateImportStatusMutation from '~/import_entities/import_groups/graphql/mutations/update_import_status.mutation.graphql';
import bulkImportSourceGroupsQuery from '~/import_entities/import_groups/graphql/queries/bulk_import_source_groups.query.graphql';

import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { statusEndpointFixture } from './fixtures';

jest.mock('~/alert');
jest.mock('~/import_entities/import_groups/graphql/services/local_storage_cache', () => ({
  LocalStorageCache: jest.fn().mockImplementation(function mock() {
    this.get = jest.fn();
    this.set = jest.fn();
    this.updateStatusByJobId = jest.fn();
  }),
}));

const FAKE_ENDPOINTS = {
  status: '/fake_status_url',
  createBulkImport: '/fake_create_bulk_import',
  jobs: '/fake_jobs',
};

describe('Bulk import resolvers', () => {
  let axiosMockAdapter;
  let client;

  const createClient = (extraResolverArgs) => {
    const mockedClient = createMockClient({
      cache: new InMemoryCache({
        fragmentMatcher: { match: () => true },
        addTypename: false,
      }),
      resolvers: createResolvers({ endpoints: FAKE_ENDPOINTS, ...extraResolverArgs }),
    });

    return mockedClient;
  };

  let results;
  beforeEach(() => {
    axiosMockAdapter = new MockAdapter(axios);
    client = createClient();

    axiosMockAdapter.onGet(FAKE_ENDPOINTS.status).reply(HTTP_STATUS_OK, statusEndpointFixture);
    client.watchQuery({ query: bulkImportSourceGroupsQuery }).subscribe(({ data }) => {
      results = data.bulkImportSourceGroups.nodes;
    });

    return waitForPromises();
  });

  afterEach(() => {
    axiosMockAdapter.restore();
  });

  describe('queries', () => {
    describe('bulkImportSourceGroups', () => {
      it('respects cached import state when provided by group manager', async () => {
        const [localStorageCache] = LocalStorageCache.mock.instances;
        const CACHED_DATA = {
          progress: {
            id: 'DEMO',
            status: 'cached',
            hasFailures: true,
          },
        };
        localStorageCache.get.mockReturnValueOnce(CACHED_DATA);

        const updatedResults = await client.query({
          query: bulkImportSourceGroupsQuery,
          fetchPolicy: 'no-cache',
        });

        expect(updatedResults.data.bulkImportSourceGroups.nodes[0].progress).toStrictEqual({
          __typename: clientTypenames.BulkImportProgress,
          ...CACHED_DATA.progress,
        });
      });

      describe('when called', () => {
        beforeEach(async () => {
          const response = await client.query({ query: bulkImportSourceGroupsQuery });
          results = response.data.bulkImportSourceGroups.nodes;
        });

        it('mirrors REST endpoint response fields', () => {
          const MIRRORED_FIELDS = [
            { from: 'id', to: 'id' },
            { from: 'full_name', to: 'fullName' },
            { from: 'full_path', to: 'fullPath' },
            { from: 'web_url', to: 'webUrl' },
          ];
          expect(
            results.every((r, idx) =>
              MIRRORED_FIELDS.every(
                (field) => r[field.to] === statusEndpointFixture.importable_data[idx][field.from],
              ),
            ),
          ).toBe(true);
        });

        it('populates each result instance with empty status', () => {
          expect(results.every((r) => r.progress === null)).toBe(true);
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
          axiosMockAdapter.resetHistory();
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
    beforeEach(() => {});

    describe('importGroup', () => {
      it('sets import status to CREATED for successful groups when request completes', async () => {
        axiosMockAdapter
          .onPost(FAKE_ENDPOINTS.createBulkImport)
          .reply(HTTP_STATUS_OK, [{ success: true, id: 1 }]);

        await client.mutate({
          mutation: importGroupsMutation,
          variables: {
            importRequests: [
              {
                sourceGroupId: statusEndpointFixture.importable_data[0].id,
                newName: 'test',
                targetNamespace: 'root',
              },
            ],
          },
        });

        await axios.waitForAll();
        expect(results[0].progress.status).toBe(STATUSES.CREATED);
      });

      it('sets import status to CREATED for successful groups when request completes with legacy response', async () => {
        axiosMockAdapter.onPost(FAKE_ENDPOINTS.createBulkImport).reply(HTTP_STATUS_OK, { id: 1 });

        await client.mutate({
          mutation: importGroupsMutation,
          variables: {
            importRequests: [
              {
                sourceGroupId: statusEndpointFixture.importable_data[0].id,
                newName: 'test',
                targetNamespace: 'root',
              },
            ],
          },
        });

        await axios.waitForAll();
        expect(results[0].progress.status).toBe(STATUSES.CREATED);
      });

      it('sets import status to FAILED and sets progress message for failed groups when request completes', async () => {
        const FAKE_ERROR_MESSAGE = 'foo';
        axiosMockAdapter
          .onPost(FAKE_ENDPOINTS.createBulkImport)
          .reply(HTTP_STATUS_OK, [{ success: false, id: 1, message: FAKE_ERROR_MESSAGE }]);

        await client.mutate({
          mutation: importGroupsMutation,
          variables: {
            importRequests: [
              {
                sourceGroupId: statusEndpointFixture.importable_data[0].id,
                newName: 'test',
                targetNamespace: 'root',
              },
            ],
          },
        });

        await axios.waitForAll();
        expect(results[0].progress.status).toBe(STATUSES.FAILED);
        expect(results[0].progress.message).toBe(FAKE_ERROR_MESSAGE);
      });
    });

    it('updateImportStatus updates status', async () => {
      axiosMockAdapter
        .onPost(FAKE_ENDPOINTS.createBulkImport)
        .reply(HTTP_STATUS_OK, [{ success: true, id: 1 }]);

      const NEW_STATUS = 'dummy';
      await client.mutate({
        mutation: importGroupsMutation,
        variables: {
          importRequests: [
            {
              sourceGroupId: statusEndpointFixture.importable_data[0].id,
              newName: 'test',
              targetNamespace: 'root',
            },
          ],
        },
      });
      await axios.waitForAll();
      await waitForPromises();

      const { id } = results[0].progress;

      const {
        data: { updateImportStatus: statusInResponse },
      } = await client.mutate({
        mutation: updateImportStatusMutation,
        variables: { id, status: NEW_STATUS, hasFailures: true },
      });

      expect(statusInResponse).toStrictEqual({
        __typename: clientTypenames.BulkImportProgress,
        id,
        message: null,
        status: NEW_STATUS,
        hasFailures: true,
      });
    });
  });
});
