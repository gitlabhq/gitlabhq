import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import { s__ } from '~/locale';
import createFlash from '~/flash';
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

export function createResolvers({ endpoints }) {
  let statusPoller;

  return {
    Query: {
      async bulkImportSourceGroups(_, vars, { client }) {
        const {
          data: { availableNamespaces },
        } = await client.query({ query: availableNamespacesQuery });

        return axios
          .get(endpoints.status, {
            params: {
              page: vars.page,
              per_page: vars.perPage,
              filter: vars.filter,
            },
          })
          .then(({ headers, data }) => {
            const pagination = parseIntPagination(normalizeHeaders(headers));

            return {
              __typename: clientTypenames.BulkImportSourceGroupConnection,
              nodes: data.importable_data.map((group) => ({
                __typename: clientTypenames.BulkImportSourceGroup,
                ...group,
                status: STATUSES.NONE,
                import_target: {
                  new_name: group.full_path,
                  target_namespace: availableNamespaces[0].full_path,
                },
              })),
              pageInfo: {
                __typename: clientTypenames.BulkImportPageInfo,
                ...pagination,
              },
            };
          });
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
        new SourceGroupsManager({ client }).updateById(sourceGroupId, (sourceGroup) => {
          // eslint-disable-next-line no-param-reassign
          sourceGroup.import_target.target_namespace = targetNamespace;
        });
      },

      setNewName(_, { newName, sourceGroupId }, { client }) {
        new SourceGroupsManager({ client }).updateById(sourceGroupId, (sourceGroup) => {
          // eslint-disable-next-line no-param-reassign
          sourceGroup.import_target.new_name = newName;
        });
      },

      async importGroup(_, { sourceGroupId }, { client }) {
        const groupManager = new SourceGroupsManager({ client });
        const group = groupManager.findById(sourceGroupId);
        groupManager.setImportStatus(group, STATUSES.SCHEDULING);
        try {
          await axios.post(endpoints.createBulkImport, {
            bulk_import: [
              {
                source_type: 'group_entity',
                source_full_path: group.full_path,
                destination_namespace: group.import_target.target_namespace,
                destination_name: group.import_target.new_name,
              },
            ],
          });
          groupManager.setImportStatus(group, STATUSES.STARTED);
          if (!statusPoller) {
            statusPoller = new StatusPoller({ client, interval: 3000 });
            statusPoller.startPolling();
          }
        } catch (e) {
          createFlash({
            message: s__('BulkImport|Importing the group failed'),
          });

          groupManager.setImportStatus(group, STATUSES.NONE);
          throw e;
        }
      },
    },
  };
}

export const createApolloClient = ({ endpoints }) =>
  createDefaultClient(createResolvers({ endpoints }), { assumeImmutableResults: true });
