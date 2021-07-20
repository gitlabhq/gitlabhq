import axios from '~/lib/utils/axios_utils';

export const pingUsage = ({ rootGetters }) => {
  const { web_url: projectUrl } = rootGetters.currentProject;

  const url = `${projectUrl}/service_ping/web_ide_clientside_preview`;

  return axios.post(url);
};

export default pingUsage;
