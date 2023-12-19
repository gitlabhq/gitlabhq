import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';

const BULK_IMPORT_ENTITIES_PATH = '/api/:version/bulk_imports/:id/entities';
const BULK_IMPORTS_ENTITIES_PATH = '/api/:version/bulk_imports/entities';
const BULK_IMPORT_ENTITIES_FAILURES_PATH =
  '/api/:version/bulk_imports/:id/entities/:entity_id/failures';

export const getBulkImportHistory = (id, params = {}) => {
  const bulkImportHistoryUrl = buildApiUrl(BULK_IMPORT_ENTITIES_PATH).replace(
    ':id',
    encodeURIComponent(id),
  );

  return axios.get(bulkImportHistoryUrl, { params });
};

export const getBulkImportsHistory = (params) =>
  axios.get(buildApiUrl(BULK_IMPORTS_ENTITIES_PATH), { params });

export const getBulkImportFailures = (id, entityId, { page, perPage }) => {
  const failuresPath = buildApiUrl(BULK_IMPORT_ENTITIES_FAILURES_PATH)
    .replace(':id', encodeURIComponent(id))
    .replace(':entity_id', encodeURIComponent(entityId));

  return axios.get(failuresPath, {
    params: {
      page,
      per_page: perPage,
    },
  });
};
