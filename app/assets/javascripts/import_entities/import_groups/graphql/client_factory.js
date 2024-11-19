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
  BulkImportPageInfo: 'ClientBulkImportPageInfo',
  BulkImportTarget: 'ClientBulkImportTarget',
  BulkImportProgress: 'ClientBulkImportProgress',
  BulkImportVersionValidation: 'ClientBulkImportVersionValidation',
  BulkImportVersionValidationFeature: 'ClientBulkImportVersionValidationFeature',
  BulkImportVersionValidationFeatures: 'ClientBulkImportVersionValidationFeatures',
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
          versionValidation: {
            __typename: clientTypenames.BulkImportVersionValidation,
            features: {
              __typename: clientTypenames.BulkImportVersionValidationFeatures,
              sourceInstanceVersion: data.version_validation.features.source_instance_version,
              projectMigration: {
                __typename: clientTypenames.BulkImportVersionValidationFeature,
                available: data.version_validation.features.project_migration.available,
                minVersion: data.version_validation.features.project_migration.min_version,
              },
            },
          },
        };
        return response;
      },
    },
    Mutation: {
      updateImportStatus(
        _,
        { id, status: newStatus, hasFailures = false },
        { client, getCacheKey },
      ) {
        const progressItem = client.readFragment({
          fragment: bulkImportSourceGroupProgressFragment,
          fragmentName: 'BulkImportSourceGroupProgress',
          id: getCacheKey({
            __typename: clientTypenames.BulkImportProgress,
            id,
          }),
        });

        if (!progressItem) return null;

        localStorageCache.updateStatusByJobId(id, newStatus, hasFailures);

        return {
          __typename: clientTypenames.BulkImportProgress,
          ...progressItem,
          id,
          status: newStatus,
          hasFailures,
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

        const { data: originalResponse } = await axios.post(endpoints.createBulkImport, {
          bulk_import: importOperations.map((op) => ({
            source_type: 'group_entity',
            source_full_path: op.group.fullPath,
            destination_namespace: op.targetNamespace,
            destination_name: op.newName,
            migrate_projects: op.migrateProjects,
            migrate_memberships: op.migrateMemberships,
          })),
        });

        const responses = Array.isArray(originalResponse)
          ? originalResponse
          : [{ success: true, id: originalResponse.id }];

        return importOperations.map((op, idx) => {
          const response = responses[idx];
          const lastImportTarget = {
            targetNamespace: op.targetNamespace,
            newName: op.newName,
          };

          const progress = {
            id: response.id || `local-${Date.now()}-${idx}`,
            status: response.success ? STATUSES.CREATED : STATUSES.FAILED,
            message: response.message || null,
            hasFailures: !response.success,
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
