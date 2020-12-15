import axios from '~/lib/utils/axios_utils';
import createDefaultClient from '~/lib/graphql';
import { STATUSES } from '../../constants';
import availableNamespacesQuery from './queries/available_namespaces.query.graphql';
import { SourceGroupsManager } from './services/source_groups_manager';

export const clientTypenames = {
  BulkImportSourceGroup: 'ClientBulkImportSourceGroup',
  AvailableNamespace: 'ClientAvailableNamespace',
};

export function createResolvers({ endpoints }) {
  return {
    Query: {
      async bulkImportSourceGroups(_, __, { client }) {
        const {
          data: { availableNamespaces },
        } = await client.query({ query: availableNamespacesQuery });

        return axios.get(endpoints.status).then(({ data }) => {
          return data.importable_data.map(group => ({
            __typename: clientTypenames.BulkImportSourceGroup,
            ...group,
            status: STATUSES.NONE,
            import_target: {
              new_name: group.full_path,
              target_namespace: availableNamespaces[0].full_path,
            },
          }));
        });
      },

      availableNamespaces: () =>
        axios.get(endpoints.availableNamespaces).then(({ data }) =>
          data.map(namespace => ({
            __typename: clientTypenames.AvailableNamespace,
            ...namespace,
          })),
        ),
    },
    Mutation: {
      setTargetNamespace(_, { targetNamespace, sourceGroupId }, { client }) {
        new SourceGroupsManager({ client }).updateById(sourceGroupId, sourceGroup => {
          // eslint-disable-next-line no-param-reassign
          sourceGroup.import_target.target_namespace = targetNamespace;
        });
      },

      setNewName(_, { newName, sourceGroupId }, { client }) {
        new SourceGroupsManager({ client }).updateById(sourceGroupId, sourceGroup => {
          // eslint-disable-next-line no-param-reassign
          sourceGroup.import_target.new_name = newName;
        });
      },

      async importGroup(_, { sourceGroupId }, { client }) {
        const groupManager = new SourceGroupsManager({ client });
        const group = groupManager.findById(sourceGroupId);
        groupManager.setImportStatus(group, STATUSES.SCHEDULING);
      },
    },
  };
}

export const createApolloClient = ({ endpoints }) =>
  createDefaultClient(createResolvers({ endpoints }), { assumeImmutableResults: true });
