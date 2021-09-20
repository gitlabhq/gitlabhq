import { DEFAULT_PER_PAGE } from '~/api';
import axios from '../lib/utils/axios_utils';
import { buildApiUrl } from './api_utils';

const PROJECTS_PATH = '/api/:version/projects.json';
const PROJECT_IMPORT_MEMBERS_PATH = '/api/:version/projects/:id/import_project_members/:project_id';

export function getProjects(query, options, callback = () => {}) {
  const url = buildApiUrl(PROJECTS_PATH);
  const defaults = {
    search: query,
    per_page: DEFAULT_PER_PAGE,
    simple: true,
  };

  if (gon.current_user_id) {
    defaults.membership = true;
  }

  return axios
    .get(url, {
      params: Object.assign(defaults, options),
    })
    .then(({ data, headers }) => {
      callback(data);
      return { data, headers };
    });
}

export function importProjectMembers(sourceId, targetId) {
  const url = buildApiUrl(PROJECT_IMPORT_MEMBERS_PATH)
    .replace(':id', sourceId)
    .replace(':project_id', targetId);
  return axios.post(url);
}
