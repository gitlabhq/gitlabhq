import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { formatGroupForGraphQLResolver } from '~/vue_shared/components/groups_list/formatter';

export const resolvers = (endpoint) => ({
  Query: {
    async groups(_, { active, search: filter, sort, parentId, page }) {
      const { data, headers } = await axios.get(endpoint, {
        params: { active, filter, sort, parent_id: parentId, page },
      });

      const normalizedHeaders = normalizeHeaders(headers);
      const pageInfo = {
        ...parseIntPagination(normalizedHeaders),
        __typename: 'LocalPageInfo',
      };

      return {
        nodes: data.map(formatGroupForGraphQLResolver),
        pageInfo,
      };
    },
  },
});
