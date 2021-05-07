import createFlash from '~/flash';
import createDefaultClient from '~/lib/graphql';
import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { STATUSES } from '../../constants';
import bulkImportSourceGroupItemFragment from './fragments/bulk_import_source_group_item.fragment.graphql';
import setImportProgressMutation from './mutations/set_import_progress.mutation.graphql';
import updateImportStatusMutation from './mutations/update_import_status.mutation.graphql';
import availableNamespacesQuery from './queries/available_namespaces.query.graphql';
import bulkImportSourceGroupQuery from './queries/bulk_import_source_group.query.graphql';
import { SourceGroupsManager } from './services/source_groups_manager';
import { StatusPoller } from './services/status_poller';
import typeDefs from './typedefs.graphql';

export const clientTypenames = {
  BulkImportSourceGroupConnection: 'ClientBulkImportSourceGroupConnection',
  BulkImportSourceGroup: 'ClientBulkImportSourceGroup',
  AvailableNamespace: 'ClientAvailableNamespace',
  BulkImportPageInfo: 'ClientBulkImportPageInfo',
  BulkImportTarget: 'ClientBulkImportTarget',
  BulkImportProgress: 'ClientBulkImportProgress',
  BulkImportValidationError: 'ClientBulkImportValidationError',
};

function makeGroup(data) {
  const result = {
    __typename: clientTypenames.BulkImportSourceGroup,
    ...data,
  };
  const NESTED_OBJECT_FIELDS = {
    import_target: clientTypenames.BulkImportTarget,
    progress: clientTypenames.BulkImportProgress,
  };

  Object.entries(NESTED_OBJECT_FIELDS).forEach(([field, type]) => {
    if (!data[field]) {
      return;
    }
    result[field] = {
      __typename: type,
      ...data[field],
    };
  });

  return result;
}

const localProgressId = (id) => `not-started-${id}`;

export function createResolvers({ endpoints, sourceUrl, GroupsManager = SourceGroupsManager }) {
  const groupsManager = new GroupsManager({
    sourceUrl,
  });

  let statusPoller;

  return {
    Query: {
      async bulkImportSourceGroup(_, { id }, { client, getCacheKey }) {
        return client.readFragment({
          fragment: bulkImportSourceGroupItemFragment,
          fragmentName: 'BulkImportSourceGroupItem',
          id: getCacheKey({
            __typename: clientTypenames.BulkImportSourceGroup,
            id,
          }),
        });
      },

      async bulkImportSourceGroups(_, vars, { client }) {
        if (!statusPoller) {
          statusPoller = new StatusPoller({
            updateImportStatus: ({ id, status_name: status }) =>
              client.mutate({
                mutation: updateImportStatusMutation,
                variables: { id, status },
              }),
            pollPath: endpoints.jobs,
          });
          statusPoller.startPolling();
        }

        return Promise.all([
          axios.get(endpoints.status, {
            params: {
              page: vars.page,
              per_page: vars.perPage,
              filter: vars.filter,
            },
          }),
          client.query({ query: availableNamespacesQuery }),
        ]).then(
          ([
            { headers, data },
            {
              data: { availableNamespaces },
            },
          ]) => {
            const pagination = parseIntPagination(normalizeHeaders(headers));

            return {
              __typename: clientTypenames.BulkImportSourceGroupConnection,
              nodes: data.importable_data.map((group) => {
                const { jobId, importState: cachedImportState } =
                  groupsManager.getImportStateFromStorageByGroupId(group.id) ?? {};

                return makeGroup({
                  ...group,
                  validation_errors: [],
                  progress: {
                    id: jobId ?? localProgressId(group.id),
                    status: cachedImportState?.status ?? STATUSES.NONE,
                  },
                  import_target: cachedImportState?.importTarget ?? {
                    new_name: group.full_path,
                    target_namespace: availableNamespaces[0]?.full_path ?? '',
                  },
                });
              }),
              pageInfo: {
                __typename: clientTypenames.BulkImportPageInfo,
                ...pagination,
              },
            };
          },
        );
      },

      availableNamespaces: () =>
        axios.get(endpoints.availableNamespaces).then(({ data }) =>
          data.map((namespace) => ({
            __typename: clientTypenames.AvailableNamespace,
            ...namespace,
          })),
        ),
    },
    Mutation: {
      setTargetNamespace: (_, { targetNamespace, sourceGroupId }) =>
        makeGroup({
          id: sourceGroupId,
          import_target: {
            target_namespace: targetNamespace,
          },
        }),

      setNewName: (_, { newName, sourceGroupId }) =>
        makeGroup({
          id: sourceGroupId,
          import_target: {
            new_name: newName,
          },
        }),

      async setImportProgress(_, { sourceGroupId, status, jobId }) {
        if (jobId) {
          groupsManager.updateImportProgress(jobId, status);
        }

        return makeGroup({
          id: sourceGroupId,
          progress: {
            id: jobId ?? localProgressId(sourceGroupId),
            status,
          },
        });
      },

      async updateImportStatus(_, { id, status }) {
        groupsManager.updateImportProgress(id, status);

        return {
          __typename: clientTypenames.BulkImportProgress,
          id,
          status,
        };
      },

      async addValidationError(_, { sourceGroupId, field, message }, { client }) {
        const {
          data: {
            bulkImportSourceGroup: { validation_errors: validationErrors, ...group },
          },
        } = await client.query({
          query: bulkImportSourceGroupQuery,
          variables: { id: sourceGroupId },
        });

        return {
          ...group,
          validation_errors: [
            ...validationErrors.filter(({ field: f }) => f !== field),
            {
              __typename: clientTypenames.BulkImportValidationError,
              field,
              message,
            },
          ],
        };
      },

      async removeValidationError(_, { sourceGroupId, field }, { client }) {
        const {
          data: {
            bulkImportSourceGroup: { validation_errors: validationErrors, ...group },
          },
        } = await client.query({
          query: bulkImportSourceGroupQuery,
          variables: { id: sourceGroupId },
        });

        return {
          ...group,
          validation_errors: validationErrors.filter(({ field: f }) => f !== field),
        };
      },

      async importGroups(_, { sourceGroupIds }, { client }) {
        const groups = await Promise.all(
          sourceGroupIds.map((id) =>
            client
              .query({
                query: bulkImportSourceGroupQuery,
                variables: { id },
              })
              .then(({ data }) => data.bulkImportSourceGroup),
          ),
        );

        const GROUPS_BEING_SCHEDULED = sourceGroupIds.map((sourceGroupId) =>
          makeGroup({
            id: sourceGroupId,
            progress: {
              id: localProgressId(sourceGroupId),
              status: STATUSES.SCHEDULING,
            },
          }),
        );

        const defaultErrorMessage = s__('BulkImport|Importing the group failed');
        axios
          .post(endpoints.createBulkImport, {
            bulk_import: groups.map((group) => ({
              source_type: 'group_entity',
              source_full_path: group.full_path,
              destination_namespace: group.import_target.target_namespace,
              destination_name: group.import_target.new_name,
            })),
          })
          .then(({ data: { id: jobId } }) => {
            groupsManager.createImportState(jobId, {
              status: STATUSES.CREATED,
              groups,
            });

            return { status: STATUSES.CREATED, jobId };
          })
          .catch((e) => {
            const message = e?.response?.data?.error ?? defaultErrorMessage;
            createFlash({ message });
            return { status: STATUSES.NONE };
          })
          .then((newStatus) =>
            sourceGroupIds.forEach((sourceGroupId) =>
              client.mutate({
                mutation: setImportProgressMutation,
                variables: { sourceGroupId, ...newStatus },
              }),
            ),
          )
          .catch(() => createFlash({ message: defaultErrorMessage }));

        return GROUPS_BEING_SCHEDULED;
      },
    },
  };
}

export const createApolloClient = ({ sourceUrl, endpoints }) =>
  createDefaultClient(
    createResolvers({ sourceUrl, endpoints }),
    { assumeImmutableResults: true },
    typeDefs,
  );
