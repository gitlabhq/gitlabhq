import axios from '~/lib/utils/axios_utils';
import { formatGroup } from 'ee_else_ce/groups/your_work/graphql/utils';

export const resolvers = (endpoint) => ({
  Query: {
    async groups(_, { search: filter, sort }) {
      const { data } = await axios.get(endpoint, {
        params: { filter, sort },
      });

      return {
        nodes: data.map(formatGroup),
      };
    },
  },
});
