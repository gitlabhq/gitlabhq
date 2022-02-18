import axios from '~/lib/utils/axios_utils';

export const pingUsage = ({ rootGetters }, metricName) => {
  const { web_url: projectUrl } = rootGetters.currentProject;

  const url = `${projectUrl}/service_ping/${metricName}`;

  return axios.post(url);
};

export default pingUsage;
