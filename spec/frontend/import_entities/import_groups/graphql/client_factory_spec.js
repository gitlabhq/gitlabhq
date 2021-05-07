import { InMemoryCache } from 'apollo-cache-inmemory';
import MockAdapter from 'axios-mock-adapter';
import { createMockClient } from 'mock-apollo-client';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import { STATUSES } from '~/import_entities/constants';
import {
  clientTypenames,
  createResolvers,
} from '~/import_entities/import_groups/graphql/client_factory';
import addValidationErrorMutation from '~/import_entities/import_groups/graphql/mutations/add_validation_error.mutation.graphql';
import importGroupsMutation from '~/import_entities/import_groups/graphql/mutations/import_groups.mutation.graphql';
import removeValidationErrorMutation from '~/import_entities/import_groups/graphql/mutations/remove_validation_error.mutation.graphql';
import setImportProgressMutation from '~/import_entities/import_groups/graphql/mutations/set_import_progress.mutation.graphql';
import setNewNameMutation from '~/import_entities/import_groups/graphql/mutations/set_new_name.mutation.graphql';
import setTargetNamespaceMutation from '~/import_entities/import_groups/graphql/mutations/set_target_namespace.mutation.graphql';
import updateImportStatusMutation from '~/import_entities/import_groups/graphql/mutations/update_import_status.mutation.graphql';
import availableNamespacesQuery from '~/import_entities/import_groups/graphql/queries/available_namespaces.query.graphql';
import bulkImportSourceGroupQuery from '~/import_entities/import_groups/graphql/queries/bulk_import_source_group.query.graphql';
import bulkImportSourceGroupsQuery from '~/import_entities/import_groups/graphql/queries/bulk_import_source_groups.query.graphql';
import { StatusPoller } from '~/import_entities/import_groups/graphql/services/status_poller';

import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';
import { statusEndpointFixture, availableNamespacesFixture } from './fixtures';

jest.mock('~/flash');
jest.mock('~/import_entities/import_groups/graphql/services/status_poller', () => ({
  StatusPoller: jest.fn().mockImplementation(function mock() {
    this.startPolling = jest.fn();
  }),
}));

const FAKE_ENDPOINTS = {
  status: '/fake_status_url',
  availableNamespaces: '/fake_available_namespaces',
  createBulkImport: '/fake_create_bulk_import',
  jobs: '/fake_jobs',
};

describe('Bulk import resolvers', () => {
  let axiosMockAdapter;
  let client;

  const createClient = (extraResolverArgs) => {
    return createMockClient({
      cache: new InMemoryCache({
        fragmentMatcher: { match: () => true },
        addTypename: false,
      }),
      resolvers: createResolvers({ endpoints: FAKE_ENDPOINTS, ...extraResolverArgs }),
    });
  };

  beforeEach(() => {
    axiosMockAdapter = new MockAdapter(axios);
    client = createClient();
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

    describe('bulkImportSourceGroup', () => {
      beforeEach(async () => {
        axiosMockAdapter.onGet(FAKE_ENDPOINTS.status).reply(httpStatus.OK, statusEndpointFixture);
        axiosMockAdapter
          .onGet(FAKE_ENDPOINTS.availableNamespaces)
          .reply(httpStatus.OK, availableNamespacesFixture);

        return client.query({
          query: bulkImportSourceGroupsQuery,
        });
      });

      it('returns group', async () => {
        const { id } = statusEndpointFixture.importable_data[0];
        const {
          data: { bulkImportSourceGroup: group },
        } = await client.query({
          query: bulkImportSourceGroupQuery,
          variables: { id: id.toString() },
        });

        expect(group).toMatchObject(statusEndpointFixture.importable_data[0]);
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

      it('respects cached import state when provided by group manager', async () => {
        const FAKE_JOB_ID = '1';
        const FAKE_STATUS = 'DEMO_STATUS';
        const FAKE_IMPORT_TARGET = {
          new_name: 'test-name',
          target_namespace: 'test-namespace',
        };
        const TARGET_INDEX = 0;

        const clientWithMockedManager = createClient({
          GroupsManager: jest.fn().mockImplementation(() => ({
            getImportStateFromStorageByGroupId(groupId) {
              if (groupId === statusEndpointFixture.importable_data[TARGET_INDEX].id) {
                return {
                  jobId: FAKE_JOB_ID,
                  importState: {
                    status: FAKE_STATUS,
                    importTarget: FAKE_IMPORT_TARGET,
                  },
                };
              }

              return null;
            },
          })),
        });

        const clientResponse = await clientWithMockedManager.query({
          query: bulkImportSourceGroupsQuery,
        });
        const clientResults = clientResponse.data.bulkImportSourceGroups.nodes;

        expect(clientResults[TARGET_INDEX].import_target).toStrictEqual(FAKE_IMPORT_TARGET);
        expect(clientResults[TARGET_INDEX].progress.status).toBe(FAKE_STATUS);
      });

      it('populates each result instance with empty import_target when there are no available namespaces', async () => {
        axiosMockAdapter.onGet(FAKE_ENDPOINTS.availableNamespaces).reply(httpStatus.OK, []);

        const response = await client.query({ query: bulkImportSourceGroupsQuery });
        results = response.data.bulkImportSourceGroups.nodes;

        expect(results.every((r) => r.import_target.target_namespace === '')).toBe(true);
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

        it('populates each result instance with status default to none', () => {
          expect(results.every((r) => r.progress.status === STATUSES.NONE)).toBe(true);
        });

        it('populates each result instance with import_target defaulted to first available namespace', () => {
          expect(
            results.every(
              (r) => r.import_target.target_namespace === availableNamespacesFixture[0].full_path,
            ),
          ).toBe(true);
        });

        it('starts polling when request completes', async () => {
          const [statusPoller] = StatusPoller.mock.instances;
          expect(statusPoller.startPolling).toHaveBeenCalled();
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
                progress: {
                  id: `test-${GROUP_ID}`,
                  status: STATUSES.NONE,
                },
                web_url: 'https://fake.host/1',
                full_path: 'fake_group_1',
                full_name: 'fake_name_1',
                import_target: {
                  target_namespace: 'root',
                  new_name: 'group1',
                },
                validation_errors: [],
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
    });

    it('setTargetNamespaces updates group target namespace', async () => {
      const NEW_TARGET_NAMESPACE = 'target';
      const {
        data: {
          setTargetNamespace: {
            id: idInResponse,
            import_target: { target_namespace: namespaceInResponse },
          },
        },
      } = await client.mutate({
        mutation: setTargetNamespaceMutation,
        variables: { sourceGroupId: GROUP_ID, targetNamespace: NEW_TARGET_NAMESPACE },
      });

      expect(idInResponse).toBe(GROUP_ID);
      expect(namespaceInResponse).toBe(NEW_TARGET_NAMESPACE);
    });

    it('setNewName updates group target name', async () => {
      const NEW_NAME = 'new';
      const {
        data: {
          setNewName: {
            id: idInResponse,
            import_target: { new_name: nameInResponse },
          },
        },
      } = await client.mutate({
        mutation: setNewNameMutation,
        variables: { sourceGroupId: GROUP_ID, newName: NEW_NAME },
      });

      expect(idInResponse).toBe(GROUP_ID);
      expect(nameInResponse).toBe(NEW_NAME);
    });

    describe('importGroup', () => {
      it('sets status to SCHEDULING when request initiates', async () => {
        axiosMockAdapter.onPost(FAKE_ENDPOINTS.createBulkImport).reply(() => new Promise(() => {}));

        client.mutate({
          mutation: importGroupsMutation,
          variables: { sourceGroupIds: [GROUP_ID] },
        });
        await waitForPromises();

        const {
          bulkImportSourceGroups: { nodes: intermediateResults },
        } = client.readQuery({
          query: bulkImportSourceGroupsQuery,
        });

        expect(intermediateResults[0].progress.status).toBe(STATUSES.SCHEDULING);
      });

      describe('when request completes', () => {
        let results;

        beforeEach(() => {
          client
            .watchQuery({
              query: bulkImportSourceGroupsQuery,
              fetchPolicy: 'cache-only',
            })
            .subscribe(({ data }) => {
              results = data.bulkImportSourceGroups.nodes;
            });
        });

        it('sets import status to CREATED when request completes', async () => {
          axiosMockAdapter.onPost(FAKE_ENDPOINTS.createBulkImport).reply(httpStatus.OK, { id: 1 });
          await client.mutate({
            mutation: importGroupsMutation,
            variables: { sourceGroupIds: [GROUP_ID] },
          });
          await waitForPromises();

          expect(results[0].progress.status).toBe(STATUSES.CREATED);
        });

        it('resets status to NONE if request fails', async () => {
          axiosMockAdapter
            .onPost(FAKE_ENDPOINTS.createBulkImport)
            .reply(httpStatus.INTERNAL_SERVER_ERROR);

          client
            .mutate({
              mutation: [importGroupsMutation],
              variables: { sourceGroupIds: [GROUP_ID] },
            })
            .catch(() => {});
          await waitForPromises();

          expect(results[0].progress.status).toBe(STATUSES.NONE);
        });
      });

      it('shows default error message when server error is not provided', async () => {
        axiosMockAdapter
          .onPost(FAKE_ENDPOINTS.createBulkImport)
          .reply(httpStatus.INTERNAL_SERVER_ERROR);

        client
          .mutate({
            mutation: importGroupsMutation,
            variables: { sourceGroupIds: [GROUP_ID] },
          })
          .catch(() => {});
        await waitForPromises();

        expect(createFlash).toHaveBeenCalledWith({ message: 'Importing the group failed' });
      });

      it('shows provided error message when error is included in backend response', async () => {
        const CUSTOM_MESSAGE = 'custom message';

        axiosMockAdapter
          .onPost(FAKE_ENDPOINTS.createBulkImport)
          .reply(httpStatus.INTERNAL_SERVER_ERROR, { error: CUSTOM_MESSAGE });

        client
          .mutate({
            mutation: importGroupsMutation,
            variables: { sourceGroupIds: [GROUP_ID] },
          })
          .catch(() => {});
        await waitForPromises();

        expect(createFlash).toHaveBeenCalledWith({ message: CUSTOM_MESSAGE });
      });
    });

    it('setImportProgress updates group progress', async () => {
      const NEW_STATUS = 'dummy';
      const FAKE_JOB_ID = 5;
      const {
        data: {
          setImportProgress: { progress },
        },
      } = await client.mutate({
        mutation: setImportProgressMutation,
        variables: { sourceGroupId: GROUP_ID, status: NEW_STATUS, jobId: FAKE_JOB_ID },
      });

      expect(progress).toMatchObject({
        id: FAKE_JOB_ID,
        status: NEW_STATUS,
      });
    });

    it('updateImportStatus returns new status', async () => {
      const NEW_STATUS = 'dummy';
      const FAKE_JOB_ID = 5;
      const {
        data: { updateImportStatus: statusInResponse },
      } = await client.mutate({
        mutation: updateImportStatusMutation,
        variables: { id: FAKE_JOB_ID, status: NEW_STATUS },
      });

      expect(statusInResponse).toMatchObject({
        id: FAKE_JOB_ID,
        status: NEW_STATUS,
      });
    });

    it('addValidationError adds error to group', async () => {
      const FAKE_FIELD = 'some-field';
      const FAKE_MESSAGE = 'some-message';
      const {
        data: {
          addValidationError: { validation_errors: validationErrors },
        },
      } = await client.mutate({
        mutation: addValidationErrorMutation,
        variables: { sourceGroupId: GROUP_ID, field: FAKE_FIELD, message: FAKE_MESSAGE },
      });

      expect(validationErrors).toMatchObject([{ field: FAKE_FIELD, message: FAKE_MESSAGE }]);
    });

    it('removeValidationError removes error from group', async () => {
      const FAKE_FIELD = 'some-field';
      const FAKE_MESSAGE = 'some-message';

      await client.mutate({
        mutation: addValidationErrorMutation,
        variables: { sourceGroupId: GROUP_ID, field: FAKE_FIELD, message: FAKE_MESSAGE },
      });

      const {
        data: {
          removeValidationError: { validation_errors: validationErrors },
        },
      } = await client.mutate({
        mutation: removeValidationErrorMutation,
        variables: { sourceGroupId: GROUP_ID, field: FAKE_FIELD },
      });

      expect(validationErrors).toMatchObject([]);
    });
  });
});
