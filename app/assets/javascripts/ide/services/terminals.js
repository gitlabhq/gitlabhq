import axios from '~/lib/utils/axios_utils';

export const baseUrl = projectPath => `/${projectPath}/ide_terminals`;

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
