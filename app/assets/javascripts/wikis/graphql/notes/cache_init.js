import wikiDiscussionSortOrder from '~/wikis/graphql/notes/wiki_discussion_sort_order.query.graphql';
import { WIKI_SORT_ORDER_STORAGE_KEY, WIKI_NOTES_DEFAULT_SORT_ORDER } from '~/wikis/constants';

export default function initCache(cache) {
  const defaultValue =
    window.localStorage.getItem(WIKI_SORT_ORDER_STORAGE_KEY) || WIKI_NOTES_DEFAULT_SORT_ORDER;

  cache.writeQuery({
    query: wikiDiscussionSortOrder,
    data: {
      wikiDiscussionSortOrder: defaultValue,
    },
  });
}
