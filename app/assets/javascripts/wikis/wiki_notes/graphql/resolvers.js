import wikiDiscussionSortOrderQuery from './wiki_discussion_sort_order.query.graphql';

export default {
  Mutation: {
    sortWikiDiscussion(_, { by }, { cache }) {
      cache.writeQuery({
        query: wikiDiscussionSortOrderQuery,
        data: {
          wikiDiscussionSortOrder: by,
        },
      });
      return by;
    },
  },
};
