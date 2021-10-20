import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';

const BULK_IMPORT_ENTITIES_PATH = '/api/:version/bulk_imports/entities';

export const getBulkImportsHistory = (params) =>
  axios.get(buildApiUrl(BULK_IMPORT_ENTITIES_PATH), { params });
