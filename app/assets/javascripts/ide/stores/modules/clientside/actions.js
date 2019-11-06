import axios from '~/lib/utils/axios_utils';

export const pingUsage = ({ rootGetters }) => {
  const { web_url: projectUrl } = rootGetters.currentProject;

  const url = `${projectUrl}/usage_ping/web_ide_clientside_preview`;

  return axios.post(url);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
