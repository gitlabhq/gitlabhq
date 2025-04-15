import axios from '~/lib/utils/axios_utils';
import { formatGroup } from 'ee_else_ce/groups/your_work/graphql/utils';

export const resolvers = (endpoint) => ({
  Query: {
    async groups(_, { search: filter, sort, parentId }) {
      const { data } = await axios.get(endpoint, {
        params: { filter, sort, parent_id: parentId },
      });

      return {
        nodes: data.map(formatGroup),
      };
    },
  },
});
