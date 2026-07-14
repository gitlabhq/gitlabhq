import { s__ } from '~/locale';
import getBoardNamespaceQuery from '../graphql/get_board_namespace.query.graphql';

// Temporary placeholder so `groupBy: status` resolves to a strategy in CE, where
// statuses (and therefore grouping) don't exist — the board renders no columns
// rather than erroring. Remove once CE-available groupings exist.
/** @type {import('./index').GroupingStrategy} */
export const placeholderStrategy = {
  property: 'status',
  label: s__('WorkItems|Status'),
  valuesQuery: getBoardNamespaceQuery,
  extractValues: () => [],
  columnFilter: () => ({}),
  moveInput: () => ({}),
  patchCard: () => {},
  headerDecoration: () => ({ type: 'none' }),
};
