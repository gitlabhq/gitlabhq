import axios from '../lib/utils/axios_utils';
import { buildApiUrl } from './api_utils';

const DEPENDENCY_PROXY_CACHE_PATH = '/api/:version/groups/:id/dependency_proxy/cache';
const PUBLISH_PACKAGE_PATH =
  '/api/:version/projects/:id/packages/generic/:package_name/:package_version/:file_name';

export function publishPackage(
  { projectPath, name, version, fileName, files },
  options,
  axiosOptions = {},
) {
  const url = buildApiUrl(PUBLISH_PACKAGE_PATH)
    .replace(':id', encodeURIComponent(projectPath))
    .replace(':package_name', name)
    .replace(':package_version', version)
    .replace(':file_name', fileName);

  const defaults = {
    status: 'default',
  };

  return axios.put(url, files[0], {
    params: Object.assign(defaults, options),
    ...axiosOptions,
  });
}

export function deleteDependencyProxyCacheList(groupId, options = {}) {
  const url = buildApiUrl(DEPENDENCY_PROXY_CACHE_PATH).replace(':id', groupId);

  return axios.delete(url, { params: { ...options } });
}
