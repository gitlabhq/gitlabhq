import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';

const GROUP_SUBGROUPS_PATH = '/-/autocomplete/group_subgroups.json';

const buildUrl = (urlRoot, url) => {
  return joinPaths(urlRoot, url);
};

export const getSubGroups = () => {
  return axios.get(buildUrl(gon.relative_url_root || '', GROUP_SUBGROUPS_PATH), {
    params: {
      group_id: gon.current_group_id,
    },
  });
};
