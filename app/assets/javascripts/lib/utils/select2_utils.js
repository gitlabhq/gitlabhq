import axios from './axios_utils';
import { normalizeHeaders, parseIntPagination } from './common_utils';

// This is used in the select2 config to replace jQuery.ajax with axios
export const select2AxiosTransport = (params) => {
  axios({
    method: params.type?.toLowerCase() || 'get',
    url: params.url,
    params: params.data,
  })
    .then((res) => {
      const results = res.data || [];
      const headers = normalizeHeaders(res.headers);
      const pagination = parseIntPagination(headers);
      const more = pagination.nextPage > pagination.page;

      params.success({
        results,
        pagination: {
          more,
        },
      });
    })
    .catch(params.error);
};
