import { getAdaptiveStatusColor } from '~/lib/utils/color_utils';
import { strategies } from 'ee_else_ce/work_items/board/grouping/strategies';

/**
 * One column's value: an `id` and `name`, plus whatever extra fields the
 * strategy's `headerDecoration` needs (e.g. `iconName`, `color` for status).
 *
 * @typedef {Object} GroupingValue
 * @property {string} id
 * @property {string} name
 */

/**
 * How a column header should render its value.
 *
 * @typedef {Object} HeaderDecoration
 * @property {'icon'|'none'} type
 * @property {string} [name]
 * @property {string} [color]
 */

/**
 * A board grouping strategy. The board splits work items into columns by one
 * attribute (right now just `status`). Each field below handles one
 * attribute-specific piece of that, so `board_view` and `column_group` don't
 * need to know or care which attribute they're grouped by. To support a new
 * attribute, write a strategy and add it to the `strategies` list.
 *
 * @typedef {Object} GroupingStrategy
 * @property {string} property - The `groupBy` property it handles, e.g. 'status'.
 * @property {string} label - Human-readable name for this dimension, e.g. 'Status'.
 * @property {Object} valuesQuery - GraphQL query listing the values that become columns.
 * @property {(data: Object) => GroupingValue[]} extractValues - Pulls the column values out of the query result.
 * @property {(value: GroupingValue) => Object} columnFilter - Query variables that filter to one column, e.g. `{ status: { name } }`.
 * @property {(item: Object) => (string|null)} itemValueId - Which column value a work item belongs to, or null if none. Used to move a card to the right column when its grouped attribute changes in a side panel.
 * @property {(value: GroupingValue) => Object} moveInput - workItemUpdate input that moves an item into the column, e.g. `{ statusWidget: { status } }`.
 * @property {(value: GroupingValue) => Object} newItemDraft - Widgets-draft fragment that pre-fills the grouped attribute when creating an item in this column, e.g. `{ STATUS: { status } }`. Read by `setNewWorkItemCache` when the create modal opens.
 * @property {(node: Object, value: GroupingValue) => void} patchCard - Mutates the cloned card in place so it matches the target column while the move is still in flight.
 * @property {(value: GroupingValue) => HeaderDecoration} headerDecoration - How the column header should render the value.
 * @property {Object} [gateQuery] - Optional GraphQL query for drag-eligibility data. Omit to allow every drop.
 * @property {(data: Object) => *} [extractGateData] - Pulls the gate data (e.g. a lookup map) out of the `gateQuery` result.
 * @property {(args: { item: Object, value: GroupingValue, gateData: * }) => boolean} [isDropAllowed] - Whether `item` can be dropped into `value`'s column. Omit to allow every drop.
 */

export const DEFAULT_GROUP_BY = { property: 'status' };

// Status grouping is EE-only, so which strategies exist depends on edition.
// The `ee_else_ce` module supplies the list; we just key it by property here.
/** @type {Object<string, GroupingStrategy>} */
const STRATEGIES = Object.fromEntries(strategies.map((strategy) => [strategy.property, strategy]));

export const groupingStrategyFor = (property) => STRATEGIES[property] ?? null;

export const hasDecorationIcon = (decoration) =>
  decoration.type === 'icon' && Boolean(decoration.name);

export const decorationIconStyle = (decoration) =>
  decoration.color ? { color: getAdaptiveStatusColor(decoration.color) } : {};
