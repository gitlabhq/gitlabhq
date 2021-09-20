import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';

export const baseUrl = (projectPath) =>
  joinPaths(gon.relative_url_root || '', `/${projectPath}/ide_terminals`);

export const checkConfig = (projectPath, branch) =>
  axios.post(`${baseUrl(projectPath)}/check_config`, {
    branch,
    format: 'json',
  });

export const create = (projectPath, branch) =>
  axios.post(baseUrl(projectPath), {
    branch,
    format: 'json',
  });
