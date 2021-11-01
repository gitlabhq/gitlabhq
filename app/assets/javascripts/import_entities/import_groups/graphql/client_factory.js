import createFlash from '~/flash';
import createDefaultClient from '~/lib/graphql';
import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { STATUSES } from '../../constants';
import { i18n, NEW_NAME_FIELD } from '../constants';
import { isAvailableForImport } from '../utils';
import bulkImportSourceGroupItemFragment from './fragments/bulk_import_source_group_item.fragment.graphql';
import bulkImportSourceGroupProgressFragment from './fragments/bulk_import_source_group_progress.fragment.graphql';
import addValidationErrorMutation from './mutations/add_validation_error.mutation.graphql';
import removeValidationErrorMutation from './mutations/remove_validation_error.mutation.graphql';
import setImportProgressMutation from './mutations/set_import_progress.mutation.graphql';
import setImportTargetMutation from './mutations/set_import_target.mutation.graphql';
import updateImportStatusMutation from './mutations/update_import_status.mutation.graphql';
import availableNamespacesQuery from './queries/available_namespaces.query.graphql';
import bulkImportSourceGroupQuery from './queries/bulk_import_source_group.query.graphql';
import groupAndProjectQuery from './queries/group_and_project.query.graphql';
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
    last_import_target: clientTypenames.BulkImportTarget,
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

async function checkImportTargetIsValid({ client, newName, targetNamespace, sourceGroupId }) {
  const {
    data: { existingGroup, existingProject },
  } = await client.query({
    query: groupAndProjectQuery,
    fetchPolicy: 'no-cache',
    variables: {
      fullPath: `${targetNamespace}/${newName}`,
    },
  });

  const variables = {
    field: NEW_NAME_FIELD,
    sourceGroupId,
  };

  if (!existingGroup && !existingProject) {
    client.mutate({
      mutation: removeValidationErrorMutation,
      variables,
    });
  } else {
    client.mutate({
      mutation: addValidationErrorMutation,
      variables: {
        ...variables,
        message: i18n.NAME_ALREADY_EXISTS,
      },
    });
  }
}

const localProgressId = (id) => `not-started-${id}`;
const nextName = (name) => `${name}-1`;

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

            const response = {
              __typename: clientTypenames.BulkImportSourceGroupConnection,
              nodes: data.importable_data.map((group) => {
                const { jobId, importState: cachedImportState } =
                  groupsManager.getImportStateFromStorageByGroupId(group.id) ?? {};

                const status = cachedImportState?.status ?? STATUSES.NONE;

                const importTarget =
                  status === STATUSES.FINISHED && cachedImportState.importTarget
                    ? {
                        target_namespace: cachedImportState.importTarget.target_namespace,
                        new_name: nextName(cachedImportState.importTarget.new_name),
                      }
                    : cachedImportState?.importTarget ?? {
                        new_name: group.full_path,
                        target_namespace: availableNamespaces[0]?.full_path ?? '',
                      };

                return makeGroup({
                  ...group,
                  validation_errors: [],
                  progress: {
                    id: jobId ?? localProgressId(group.id),
                    status,
                  },
                  import_target: importTarget,
                  last_import_target: cachedImportState?.importTarget ?? null,
                });
              }),
              pageInfo: {
                __typename: clientTypenames.BulkImportPageInfo,
                ...pagination,
              },
            };

            setTimeout(() => {
              response.nodes.forEach((group) => {
                if (isAvailableForImport(group)) {
                  checkImportTargetIsValid({
                    client,
                    newName: group.import_target.new_name,
                    targetNamespace: group.import_target.target_namespace,
                    sourceGroupId: group.id,
                  });
                }
              });
            });

            return response;
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
      setImportTarget(_, { targetNamespace, newName, sourceGroupId }, { client }) {
        checkImportTargetIsValid({
          client,
          sourceGroupId,
          targetNamespace,
          newName,
        });

        return makeGroup({
          id: sourceGroupId,
          import_target: {
            target_namespace: targetNamespace,
            new_name: newName,
            id: sourceGroupId,
          },
        });
      },

      async setImportProgress(_, { sourceGroupId, status, jobId, importTarget }) {
        if (jobId) {
          groupsManager.updateImportProgress(jobId, status);
        }

        return makeGroup({
          id: sourceGroupId,
          progress: {
            id: jobId ?? localProgressId(sourceGroupId),
            status,
          },
          last_import_target: {
            __typename: clientTypenames.BulkImportTarget,
            ...importTarget,
          },
        });
      },

      async updateImportStatus(_, { id, status: newStatus }, { client, getCacheKey }) {
        groupsManager.updateImportProgress(id, newStatus);

        const progressItem = client.readFragment({
          fragment: bulkImportSourceGroupProgressFragment,
          fragmentName: 'BulkImportSourceGroupProgress',
          id: getCacheKey({
            __typename: clientTypenames.BulkImportProgress,
            id,
          }),
        });

        const isInProgress = Boolean(progressItem);
        const { status: currentStatus } = progressItem ?? {};
        if (newStatus === STATUSES.FINISHED && isInProgress && currentStatus !== newStatus) {
          const groups = groupsManager.getImportedGroupsByJobId(id);

          groups.forEach(async ({ id: groupId, importTarget }) => {
            client.mutate({
              mutation: setImportTargetMutation,
              variables: {
                sourceGroupId: groupId,
                targetNamespace: importTarget.target_namespace,
                newName: nextName(importTarget.new_name),
              },
            });
          });
        }

        return {
          __typename: clientTypenames.BulkImportProgress,
          id,
          status: newStatus,
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
            sourceGroupIds.forEach((sourceGroupId, idx) =>
              client.mutate({
                mutation: setImportProgressMutation,
                variables: { sourceGroupId, ...newStatus, importTarget: groups[idx].import_target },
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
  createDefaultClient(createResolvers({ sourceUrl, endpoints }), { typeDefs });
