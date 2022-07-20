import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import axios from '~/lib/utils/axios_utils';
import { fetchLogsTree } from './log_tree';

Vue.use(VueApollo);

const defaultClient = createDefaultClient(
  {
    Query: {
      commit(_, { path, fileName, maxOffset }) {
        return new Promise((resolve) => {
          fetchLogsTree(
            defaultClient,
            path,
            '0',
            {
              resolve,
              entry: {
                name: fileName,
              },
            },
            maxOffset,
          );
        });
      },
      readme(_, { url }) {
        return axios
          .get(url, { params: { format: 'json', viewer: 'rich' } })
          .then(({ data }) => ({ ...data, __typename: 'ReadmeFile' }));
      },
    },
  },
  {
    cacheConfig: {
      dataIdFromObject: (obj) => {
        /* eslint-disable @gitlab/require-i18n-strings */
        // eslint-disable-next-line no-underscore-dangle
        switch (obj.__typename) {
          // We need to create a dynamic ID for each entry
          // Each entry can have the same ID as the ID is a commit ID
          // So we create a unique cache ID with the path and the ID
          case 'TreeEntry':
          case 'Submodule':
          case 'Blob':
            return `${encodeURIComponent(obj.flatPath)}-${obj.id}`;
          default:
            // If the type doesn't match any of the above we fallback
            // to using the default Apollo ID
            // eslint-disable-next-line no-underscore-dangle
            return obj.id || obj._id;
        }
        /* eslint-enable @gitlab/require-i18n-strings */
      },
    },
  },
);

export default new VueApollo({
  defaultClient,
});
