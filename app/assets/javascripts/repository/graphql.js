import { IntrospectionFragmentMatcher } from 'apollo-cache-inmemory';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import axios from '~/lib/utils/axios_utils';
import introspectionQueryResultData from './fragmentTypes.json';
import { fetchLogsTree } from './log_tree';

Vue.use(VueApollo);

// We create a fragment matcher so that we can create a fragment from an interface
// Without this, Apollo throws a heuristic fragment matcher warning
const fragmentMatcher = new IntrospectionFragmentMatcher({
  introspectionQueryResultData,
});

const defaultClient = createDefaultClient(
  {
    Query: {
      commit(_, { path, fileName, type, maxOffset }) {
        return new Promise((resolve) => {
          fetchLogsTree(
            defaultClient,
            path,
            '0',
            {
              resolve,
              entry: {
                name: fileName,
                type,
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
      fragmentMatcher,
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
    assumeImmutableResults: true,
  },
);

export default new VueApollo({
  defaultClient,
});
