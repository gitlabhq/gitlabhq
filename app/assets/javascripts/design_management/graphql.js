import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import produce from 'immer';
import { uniqueId } from 'lodash';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import axios from '~/lib/utils/axios_utils';
import activeDiscussionQuery from './graphql/queries/active_discussion.query.graphql';
import getDesignQuery from './graphql/queries/get_design.query.graphql';
import typeDefs from './graphql/typedefs.graphql';
import { addPendingTodoToStore } from './utils/cache_update';
import { extractTodoIdFromDeletePath, createPendingTodo } from './utils/design_management_utils';
import { CREATE_DESIGN_TODO_EXISTS_ERROR } from './utils/error_messages';

Vue.use(VueApollo);

const resolvers = {
  Mutation: {
    updateActiveDiscussion: (_, { id = null, source }, { cache }) => {
      const sourceData = cache.readQuery({ query: activeDiscussionQuery });

      const data = produce(sourceData, (draftData) => {
        draftData.activeDiscussion = {
          __typename: 'ActiveDiscussion',
          id,
          source,
        };
      });

      cache.writeQuery({ query: activeDiscussionQuery, data });
    },
    createDesignTodo: (
      _,
      { projectPath, issueId, designId, issueIid, filenames, atVersion },
      { cache },
    ) => {
      return axios
        .post(`/${projectPath}/todos`, {
          issue_id: issueId,
          issuable_id: designId,
          issuable_type: 'design',
        })
        .then(({ data }) => {
          const { delete_path } = data;
          const todoId = extractTodoIdFromDeletePath(delete_path);
          if (!todoId) {
            return {
              errors: [
                {
                  message: CREATE_DESIGN_TODO_EXISTS_ERROR,
                },
              ],
            };
          }

          const pendingTodo = createPendingTodo(todoId);
          addPendingTodoToStore(cache, pendingTodo, getDesignQuery, {
            fullPath: projectPath,
            iid: issueIid,
            filenames,
            atVersion,
          });

          return pendingTodo;
        });
    },
  },
};

const defaultClient = createDefaultClient(
  resolvers,
  // This config is added temporarily to resolve an issue with duplicate design IDs.
  // Should be removed as soon as https://gitlab.com/gitlab-org/gitlab/issues/13495 is resolved
  {
    cacheConfig: {
      dataIdFromObject: (object) => {
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
