import { getAdaptiveStatusColor } from '~/lib/utils/color_utils';
import { strategies } from 'ee_else_ce/work_items/board/grouping/strategies';

/**
 * One column's value: an `id` and `name` plus any attribute-specific fields the
 * strategy's `headerDecoration` reads (e.g. `iconName`, `color` for status).
 *
 * @typedef {Object} GroupingValue
 * @property {string} id
 * @property {string} name
 */

/**
 * How a column header renders its value.
 *
 * @typedef {Object} HeaderDecoration
 * @property {'icon'|'none'} type
 * @property {string} [name]
 * @property {string} [color]
 */

/**
 * A board grouping strategy. The work items board groups work items into columns
 * by an attribute (today only `status`; assignee/label/milestone/… in future).
 * Each field isolates one attribute-specific decision, keeping `board_view` and
 * `column_group` attribute-agnostic — so a new attribute is added by writing a
 * strategy and adding it to the `strategies` list, with no board-component changes.
 *
 * @typedef {Object} GroupingStrategy
 * @property {string} property - The `groupBy` property it handles, e.g. 'status'.
 * @property {string} label - Human-readable name for this dimension, e.g. 'Status'.
 * @property {Object} valuesQuery - GraphQL query listing the values that become columns.
 * @property {(data: Object) => GroupingValue[]} extractValues - Pulls the column values from the query result.
 * @property {(value: GroupingValue) => Object} columnFilter - work-items query variables that filter a column, e.g. `{ status: { name } }`.
 * @property {(value: GroupingValue) => Object} moveInput - workItemUpdate input fragment that moves an item into the column, e.g. `{ statusWidget: { status } }`.
 * @property {(node: Object, value: GroupingValue) => void} patchCard - Mutates the cloned card in place so its attribute matches the target column optimistically.
 * @property {(value: GroupingValue) => HeaderDecoration} headerDecoration - How the column header renders the value.
 * @property {Object} [gateQuery] - Optional GraphQL query for drag-eligibility data. Omit to allow all drops.
 * @property {(data: Object) => *} [extractGateData] - Pulls gate data (e.g. a lookup map) from the `gateQuery` result.
 * @property {(args: { item: Object, value: GroupingValue, gateData: * }) => boolean} [isDropAllowed] - Whether the dragged work item `item` may be dropped into `value`'s column. Omit to allow all drops.
 */

// The available strategies differ by edition (status is EE-only), so the list
// is supplied by an `ee_else_ce` module and keyed by property here.
/** @type {Object<string, GroupingStrategy>} */
const STRATEGIES = Object.fromEntries(strategies.map((strategy) => [strategy.property, strategy]));

/**
 * @param {string} property
 * @returns {GroupingStrategy|null} The strategy for the groupBy property, or null when unsupported.
 */
export const groupingStrategyFor = (property) => STRATEGIES[property] ?? null;

/**
 * @param {HeaderDecoration} decoration
 * @returns {boolean} Whether the decoration should render an icon.
 */
export const hasDecorationIcon = (decoration) =>
  decoration.type === 'icon' && Boolean(decoration.name);

/**
 * @param {HeaderDecoration} decoration
 * @returns {Object} Inline style for the decoration icon, adapted for dark mode.
 */
export const decorationIconStyle = (decoration) =>
  decoration.color ? { color: getAdaptiveStatusColor(decoration.color) } : {};
