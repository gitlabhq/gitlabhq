import axios from '~/lib/utils/axios_utils';

export const fetchOverrides = (overridesPath, { page, perPage }) => {
  return axios.get(overridesPath, {
    params: {
      page,
      per_page: perPage,
    },
  });
};
