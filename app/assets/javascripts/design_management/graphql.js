import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { uniqueId } from 'lodash';
import produce from 'immer';
import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import createDefaultClient from '~/lib/graphql';
import activeDiscussionQuery from './graphql/queries/active_discussion.query.graphql';
import typeDefs from './graphql/typedefs.graphql';

Vue.use(VueApollo);

const resolvers = {
  Mutation: {
    updateActiveDiscussion: (_, { id = null, source }, { cache }) => {
      const sourceData = cache.readQuery({ query: activeDiscussionQuery });

      const data = produce(sourceData, draftData => {
        // eslint-disable-next-line no-param-reassign
        draftData.activeDiscussion = {
          __typename: 'ActiveDiscussion',
          id,
          source,
        };
      });

      cache.writeQuery({ query: activeDiscussionQuery, data });
    },
  },
};

const defaultClient = createDefaultClient(
  resolvers,
  // This config is added temporarily to resolve an issue with duplicate design IDs.
  // Should be removed as soon as https://gitlab.com/gitlab-org/gitlab/issues/13495 is resolved
  {
    cacheConfig: {
      dataIdFromObject: object => {
        // eslint-disable-next-line no-underscore-dangle, @gitlab/require-i18n-strings
        if (object.__typename === 'Design') {
          return object.id && object.image ? `${object.id}-${object.image}` : uniqueId();
        }
        return defaultDataIdFromObject(object);
      },
    },
    typeDefs,
    assumeImmutableResults: true,
  },
);

export default new VueApollo({
  defaultClient,
});
