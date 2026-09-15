import axios from '~/lib/utils/axios_utils';
import { DEFAULT_PER_PAGE } from '~/api';
import { buildApiUrl } from './api_utils';

const ADMIN_SSH_CERTIFICATES_PATH = '/api/:version/admin/ssh_certificates';

export function getAdminSshCertificates({ page = 1, perPage = DEFAULT_PER_PAGE } = {}) {
  const url = buildApiUrl(ADMIN_SSH_CERTIFICATES_PATH);

  return axios.get(url, { params: { page, per_page: perPage } });
}
