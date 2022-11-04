import workItemQuery from './graphql/work_item.query.graphql';
import workItemByIidQuery from './graphql/work_item_by_iid.query.graphql';

export function getWorkItemQuery(isFetchedByIid) {
  return isFetchedByIid ? workItemByIidQuery : workItemQuery;
}
