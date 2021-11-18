import createDefaultClient from '~/lib/graphql';
import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { STATUSES } from '../../constants';
import bulkImportSourceGroupItemFragment from './fragments/bulk_import_source_group_item.fragment.graphql';
import bulkImportSourceGroupProgressFragment from './fragments/bulk_import_source_group_progress.fragment.graphql';
import { LocalStorageCache } from './services/local_storage_cache';
import typeDefs from './typedefs.graphql';

export const clientTypenames = {
  BulkImportSourceGroupConnection: 'ClientBulkImportSourceGroupConnection',
  BulkImportSourceGroup: 'ClientBulkImportSourceGroup',
  AvailableNamespace: 'ClientAvailableNamespace',
  BulkImportPageInfo: 'ClientBulkImportPageInfo',
  BulkImportTarget: 'ClientBulkImportTarget',
  BulkImportProgress: 'ClientBulkImportProgress',
};

function makeLastImportTarget(data) {
  return {
    __typename: clientTypenames.BulkImportTarget,
    ...data,
  };
}

function makeProgress(data) {
  return {
    __typename: clientTypenames.BulkImportProgress,
    ...data,
  };
}

function makeGroup(data) {
  return {
    __typename: clientTypenames.BulkImportSourceGroup,
    ...data,
    progress: data.progress
      ? makeProgress({
          id: `LOCAL-PROGRESS-${data.id}`,
          ...data.progress,
        })
      : null,
    lastImportTarget: data.lastImportTarget
      ? makeLastImportTarget({
          id: data.id,
          ...data.lastImportTarget,
        })
      : null,
  };
}

function getGroupFromCache({ client, id, getCacheKey }) {
  return client.readFragment({
    fragment: bulkImportSourceGroupItemFragment,
    fragmentName: 'BulkImportSourceGroupItem',
    id: getCacheKey({
      __typename: clientTypenames.BulkImportSourceGroup,
      id,
    }),
  });
}

export function createResolvers({ endpoints }) {
  const localStorageCache = new LocalStorageCache();

  return {
    Query: {
      async bulkImportSourceGroups(_, vars) {
        const { headers, data } = await axios.get(endpoints.status, {
          params: {
            page: vars.page,
            per_page: vars.perPage,
            filter: vars.filter,
          },
        });

        const pagination = parseIntPagination(normalizeHeaders(headers));

        const response = {
          __typename: clientTypenames.BulkImportSourceGroupConnection,
          nodes: data.importable_data.map((group) => {
            return makeGroup({
              id: group.id,
              webUrl: group.web_url,
              fullPath: group.full_path,
              fullName: group.full_name,
              ...group,
              ...localStorageCache.get(group.web_url),
            });
          }),
          pageInfo: {
            __typename: clientTypenames.BulkImportPageInfo,
            ...pagination,
          },
        };
        return response;
      },

      availableNamespaces: () =>
        axios.get(endpoints.availableNamespaces).then(({ data }) =>
          data.map((namespace) => ({
            __typename: clientTypenames.AvailableNamespace,
            id: namespace.id,
            fullPath: namespace.full_path,
          })),
        ),
    },
    Mutation: {
      async updateImportStatus(_, { id, status: newStatus }, { client, getCacheKey }) {
        const progressItem = client.readFragment({
          fragment: bulkImportSourceGroupProgressFragment,
          fragmentName: 'BulkImportSourceGroupProgress',
          id: getCacheKey({
            __typename: clientTypenames.BulkImportProgress,
            id,
          }),
        });

        if (!progressItem) return null;

        localStorageCache.updateStatusByJobId(id, newStatus);

        return {
          __typename: clientTypenames.BulkImportProgress,
          ...progressItem,
          id,
          status: newStatus,
        };
      },

      async importGroups(_, { importRequests }, { client, getCacheKey }) {
        const importOperations = importRequests.map((importRequest) => {
          const group = getGroupFromCache({
            client,
            getCacheKey,
            id: importRequest.sourceGroupId,
          });

          return {
            group,
            ...importRequest,
          };
        });

        const {
          data: { id: jobId },
        } = await axios.post(endpoints.createBulkImport, {
          bulk_import: importOperations.map((op) => ({
            source_type: 'group_entity',
            source_full_path: op.group.fullPath,
            destination_namespace: op.targetNamespace,
            destination_name: op.newName,
          })),
        });

        return importOperations.map((op) => {
          const lastImportTarget = {
            targetNamespace: op.targetNamespace,
            newName: op.newName,
          };

          const progress = {
            id: jobId,
            status: STATUSES.CREATED,
          };

          localStorageCache.set(op.group.webUrl, { progress, lastImportTarget });

          return makeGroup({ ...op.group, progress, lastImportTarget });
        });
      },
    },
  };
}

export const createApolloClient = ({ sourceUrl, endpoints }) =>
  createDefaultClient(createResolvers({ sourceUrl, endpoints }), { typeDefs });
