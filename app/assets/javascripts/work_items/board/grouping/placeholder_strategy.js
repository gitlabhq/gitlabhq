import { s__ } from '~/locale';
import getBoardNamespaceQuery from '../graphql/get_board_namespace.query.graphql';

// CE has no statuses, so there's nothing real to group by yet. This stands in
// for a status strategy so `groupBy: status` still resolves to something, and
// the board just renders no columns instead of erroring. Remove once CE gets
// a real grouping to use.
/** @type {import('./index').GroupingStrategy} */
export const placeholderStrategy = {
  property: 'status',
  label: s__('WorkItems|Status'),
  valuesQuery: getBoardNamespaceQuery,
  extractValues: () => [],
  columnFilter: () => ({}),
  moveInput: () => ({}),
  newItemDraft: () => ({}),
  patchCard: () => {},
  headerDecoration: () => ({ type: 'none' }),
};
