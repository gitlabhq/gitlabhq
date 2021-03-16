import createFlash from '~/flash';
import createDefaultClient from '~/lib/graphql';
import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { STATUSES } from '../../constants';
import availableNamespacesQuery from './queries/available_namespaces.query.graphql';
import { SourceGroupsManager } from './services/source_groups_manager';
import { StatusPoller } from './services/status_poller';

export const clientTypenames = {
  BulkImportSourceGroupConnection: 'ClientBulkImportSourceGroupConnection',
  BulkImportSourceGroup: 'ClientBulkImportSourceGroup',
  AvailableNamespace: 'ClientAvailableNamespace',
  BulkImportPageInfo: 'ClientBulkImportPageInfo',
};

export function createResolvers({ endpoints, sourceUrl, GroupsManager = SourceGroupsManager }) {
  let statusPoller;

  let sourceGroupManager;
  const getGroupsManager = (client) => {
    if (!sourceGroupManager) {
      sourceGroupManager = new GroupsManager({ client, sourceUrl });
    }
    return sourceGroupManager;
  };

  return {
    Query: {
      async bulkImportSourceGroups(_, vars, { client }) {
        if (!statusPoller) {
          statusPoller = new StatusPoller({
            groupManager: getGroupsManager(client),
            pollPath: endpoints.jobs,
          });
          statusPoller.startPolling();
        }

        const groupsManager = getGroupsManager(client);
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
                const cachedImportState = groupsManager.getImportStateFromStorageByGroupId(
                  group.id,
                );

                return {
                  __typename: clientTypenames.BulkImportSourceGroup,
                  ...group,
                  status: cachedImportState?.status ?? STATUSES.NONE,
                  import_target: cachedImportState?.importTarget ?? {
                    new_name: group.full_path,
                    target_namespace: availableNamespaces[0]?.full_path ?? '',
                  },
                };
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
      setTargetNamespace(_, { targetNamespace, sourceGroupId }, { client }) {
        getGroupsManager(client).updateById(sourceGroupId, (sourceGroup) => {
          // eslint-disable-next-line no-param-reassign
          sourceGroup.import_target.target_namespace = targetNamespace;
        });
      },

      setNewName(_, { newName, sourceGroupId }, { client }) {
        getGroupsManager(client).updateById(sourceGroupId, (sourceGroup) => {
          // eslint-disable-next-line no-param-reassign
          sourceGroup.import_target.new_name = newName;
        });
      },

      async importGroup(_, { sourceGroupId }, { client }) {
        const groupManager = getGroupsManager(client);
        const group = groupManager.findById(sourceGroupId);
        groupManager.setImportStatus(group, STATUSES.SCHEDULING);
        try {
          const response = await axios.post(endpoints.createBulkImport, {
            bulk_import: [
              {
                source_type: 'group_entity',
                source_full_path: group.full_path,
                destination_namespace: group.import_target.target_namespace,
                destination_name: group.import_target.new_name,
              },
            ],
          });
          groupManager.startImport({ group, importId: response.data.id });
        } catch (e) {
          const message = e?.response?.data?.error ?? s__('BulkImport|Importing the group failed');
          createFlash({ message });
          groupManager.setImportStatus(group, STATUSES.NONE);
          throw e;
        }
      },
    },
  };
}

export const createApolloClient = ({ sourceUrl, endpoints }) =>
  createDefaultClient(createResolvers({ sourceUrl, endpoints }), { assumeImmutableResults: true });
