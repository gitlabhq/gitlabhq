import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { IntrospectionFragmentMatcher } from 'apollo-cache-inmemory';
import axios from '~/lib/utils/axios_utils';
import createDefaultClient from '~/lib/graphql';
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
      commit(_, { path, fileName, type }) {
        return new Promise(resolve => {
          fetchLogsTree(defaultClient, path, '0', {
            resolve,
            entry: {
              name: fileName,
              type,
            },
          });
        });
      },
      readme(_, { url }) {
        return axios
          .get(url, { params: { viewer: 'rich', format: 'json' } })
          .then(({ data }) => ({ ...data, __typename: 'ReadmeFile' }));
      },
    },
  },
  {
    cacheConfig: {
      fragmentMatcher,
      dataIdFromObject: obj => {
        /* eslint-disable @gitlab/i18n/no-non-i18n-strings */
        // eslint-disable-next-line no-underscore-dangle
        switch (obj.__typename) {
          // We need to create a dynamic ID for each entry
          // Each entry can have the same ID as the ID is a commit ID
          // So we create a unique cache ID with the path and the ID
          case 'TreeEntry':
          case 'Submodule':
          case 'Blob':
            return `${obj.flatPath}-${obj.id}`;
          default:
            // If the type doesn't match any of the above we fallback
            // to using the default Apollo ID
            // eslint-disable-next-line no-underscore-dangle
            return obj.id || obj._id;
        }
        /* eslint-enable @gitlab/i18n/no-non-i18n-strings */
      },
    },
  },
);

export default new VueApollo({
  defaultClient,
});
