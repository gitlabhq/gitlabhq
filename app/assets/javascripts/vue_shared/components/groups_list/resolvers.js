import axios from '~/lib/utils/axios_utils';
import { normalizeHeaders, parseCursorPagination } from '~/lib/utils/common_utils';
import { formatGroupForGraphQLResolver } from '~/vue_shared/components/groups_list/formatter';

export const resolvers = (endpoint) => ({
  Query: {
    async groups(_, { active, search: filter, sort, parentId, pagination, before, after }) {
      const { data, headers } = await axios.get(endpoint, {
        params: {
          active,
          filter,
          sort,
          parent_id: parentId,
          cursor: before || after,
          pagination,
        },
      });

      const normalizedHeaders = normalizeHeaders(headers);
      const pageInfo = parseCursorPagination(normalizedHeaders);

      return {
        nodes: data.map(formatGroupForGraphQLResolver),
        pageInfo: {
          __typename: 'LocalPageInfo',
          ...pageInfo,
        },
      };
    },
  },
});
