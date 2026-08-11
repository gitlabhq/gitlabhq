import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { WIDGET_TYPE_LABELS } from '~/work_items/constants';
import searchLabelsQuery from '~/work_items/list/graphql/search_labels.query.graphql';

/**
 * A new work item created from a board column inherits both the column's grouping
 * (handled by the grouping strategy's `newItemDraft`) and the board's active filters.
 * Each "inheritor" here maps one filterable attribute to a new-work-item widgets-draft
 * fragment (keyed by widget type, e.g. `{ LABELS: { labels: { nodes } } }`), resolving
 * filter values (names/titles) to the full objects the widget draft needs.
 *
 * Add a new inherited attribute (assignees, milestone, …) by writing an inheritor and
 * adding it to `FILTER_INHERITORS` — no board-component changes required.
 *
 * @typedef {Object} FilterInheritor
 * @property {string} widgetType - The widgets-draft key this inheritor owns (e.g. `LABELS`).
 *   Listed in `INHERITED_WIDGET_TYPES` so the board can reset it before re-seeding.
 * @property {(context: InheritContext) => Promise<Object>} resolve - Draft fragment, or `{}` when the filter is absent.
 *
 * @typedef {Object} InheritContext
 * @property {Object} apolloClient
 * @property {string} fullPath
 * @property {boolean} isGroup
 * @property {Object} filters - The board's active filters (apiFilterParams shape). Only
 *   positive `IS` filters are read; negated/union filters live under other keys and are skipped.
 */

/** @type {FilterInheritor} */
const labelsInheritor = {
  widgetType: WIDGET_TYPE_LABELS,

  async resolve({ apolloClient, fullPath, isGroup, filters }) {
    // `labelName` holds only positive (IS) label filters; negated/union labels use
    // `not.labelName`/`labelNames` and are intentionally not inherited. It is a string
    // for a single filtered label and an array for several, so normalize to an array.
    const filtered = filters?.labelName;
    const titles = Array.isArray(filtered) ? filtered : [filtered].filter(Boolean);
    if (!titles.length) {
      return {};
    }

    // Resolve each title to a full label object; the filter only carries titles, but the
    // widget draft needs `{ id, title, color, textColor }`. Query per title so resolution
    // does not depend on how many labels the namespace has.
    const results = await Promise.all(
      titles.map((title) =>
        apolloClient.query({
          query: searchLabelsQuery,
          variables: { fullPath, isProject: !isGroup, search: title },
        }),
      ),
    );

    const nodesById = new Map();
    results.forEach(({ data }) => {
      const labels = data?.group?.labels?.nodes ?? data?.project?.labels?.nodes ?? [];
      labels
        .filter((label) => titles.includes(label.title))
        .forEach((label) => nodesById.set(label.id, label));
    });

    const nodes = [...nodesById.values()];
    return nodes.length ? { [WIDGET_TYPE_LABELS]: { labels: { nodes } } } : {};
  },
};

export const FILTER_INHERITORS = [labelsInheritor];

/**
 * Widgets-draft keys the inheritors manage. The board resets these before re-seeding so a
 * filter that is no longer active does not linger in the draft shared across board views.
 */
export const INHERITED_WIDGET_TYPES = FILTER_INHERITORS.map((inheritor) => inheritor.widgetType);

/**
 * Merges every inheritor's widgets-draft fragment for the board's active filters.
 * A failing inheritor is logged and skipped so it can't block opening the create modal.
 *
 * @param {InheritContext} context
 * @returns {Promise<Object>} Combined widgets-draft fragment (`{}` when nothing is inherited).
 */
export const resolveInheritedWidgetsDraft = async (context) => {
  const fragments = await Promise.all(
    FILTER_INHERITORS.map(async (inheritor) => {
      try {
        return await inheritor.resolve(context);
      } catch (error) {
        Sentry.captureException(error);
        return {};
      }
    }),
  );

  return Object.assign({}, ...fragments);
};
