import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

const defaultClient = createDefaultClient({
  Query: {
    files() {
      return [
        {
          __typename: 'file',
          id: 1,
          name: 'app',
          flatPath: 'app',
          type: 'folder',
        },
        {
          __typename: 'file',
          id: 2,
          name: 'gitlab-svg',
          flatPath: 'gitlab-svg',
          type: 'commit',
        },
        {
          __typename: 'file',
          id: 3,
          name: 'index.js',
          flatPath: 'index.js',
          type: 'blob',
        },
        {
          __typename: 'file',
          id: 4,
          name: 'test.pdf',
          flatPath: 'fixtures/test.pdf',
          type: 'blob',
        },
      ];
    },
  },
});

export default new VueApollo({
  defaultClient,
});
