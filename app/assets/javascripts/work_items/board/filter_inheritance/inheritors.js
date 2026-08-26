import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_MILESTONE,
} from '~/work_items/constants';
import searchLabelsQuery from '~/work_items/list/graphql/search_labels.query.graphql';
import usersSearchQuery from '~/graphql_shared/queries/workspace_autocomplete_users.query.graphql';
import searchMilestonesQuery from '../graphql/search_milestones.query.graphql';

/**
 * When you create a work item from a board column, it should pick up both the
 * column's grouping (the grouping strategy's `newItemDraft` handles that) and
 * the board's active filters. Each "inheritor" below owns one filterable
 * attribute: it takes the filter's raw values (names/titles) and turns them
 * into the full objects the new-item widgets draft needs, keyed by widget
 * type (e.g. `{ LABELS: { labels: { nodes } } }`).
 *
 * Available inheritors differ by edition, so the list lives behind `ee_else_ce` and is
 * consumed in `./index.js`. Add a CE inheritor here; add an EE-only one in the EE
 * counterpart — no board-component changes required.
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

// apiFilterParams stores a single filtered value as a string and several as an array;
// normalize to an array of the present values so inheritors can treat both the same way.
export const normalizeFilterValue = (value) =>
  Array.isArray(value) ? value : [value].filter(Boolean);

/** @type {FilterInheritor} */
const labelsInheritor = {
  widgetType: WIDGET_TYPE_LABELS,

  async resolve({ apolloClient, fullPath, isGroup, filters }) {
    const titles = normalizeFilterValue(filters?.labelName);
    if (!titles.length) {
      return {};
    }

    // The filter only gives us label titles, but the widget draft needs full
    // label objects (`{ id, title, color, textColor }`). Query per title so
    // this works the same no matter how many labels the namespace has. Using
    // `allSettled` means one failed lookup only drops that label, not every
    // label that resolved.
    const results = await Promise.allSettled(
      titles.map((title) =>
        apolloClient.query({
          query: searchLabelsQuery,
          variables: { fullPath, isProject: !isGroup, search: title },
        }),
      ),
    );

    const nodesById = new Map();
    results.forEach((result) => {
      if (result.status === 'rejected') {
        Sentry.captureException(result.reason);
        return;
      }
      const { data } = result.value;
      const labels = data?.group?.labels?.nodes ?? data?.project?.labels?.nodes ?? [];
      labels
        .filter((label) => titles.includes(label.title))
        .forEach((label) => nodesById.set(label.id, label));
    });

    const nodes = [...nodesById.values()];
    return nodes.length ? { [WIDGET_TYPE_LABELS]: { labels: { nodes } } } : {};
  },
};

/** @type {FilterInheritor} */
const assigneesInheritor = {
  widgetType: WIDGET_TYPE_ASSIGNEES,

  async resolve({ apolloClient, fullPath, isGroup, filters }) {
    const usernames = normalizeFilterValue(filters?.assigneeUsernames);
    if (!usernames.length) {
      return {};
    }

    // The filter only carries usernames, but the widget draft needs full user objects.
    // Query per username so resolution does not depend on the namespace's member count.
    // allSettled so one failed lookup drops only that assignee, not every one that resolved.
    const results = await Promise.allSettled(
      usernames.map((username) =>
        apolloClient.query({
          query: usersSearchQuery,
          variables: { fullPath, isProject: !isGroup, search: username },
        }),
      ),
    );

    const nodesById = new Map();
    results.forEach((result) => {
      if (result.status === 'rejected') {
        Sentry.captureException(result.reason);
        return;
      }
      const { data } = result.value;
      const users = (isGroup ? data?.groupNamespace?.users : data?.namespace?.users) ?? [];
      users
        .filter((user) => usernames.includes(user.username))
        .forEach((user) => nodesById.set(user.id, user));
    });

    const nodes = [...nodesById.values()];
    return nodes.length ? { [WIDGET_TYPE_ASSIGNEES]: { assignees: { nodes } } } : {};
  },
};

/** @type {FilterInheritor} */
const milestoneInheritor = {
  widgetType: WIDGET_TYPE_MILESTONE,

  async resolve({ apolloClient, fullPath, isGroup, filters }) {
    const [title] = normalizeFilterValue(filters?.milestoneTitle);
    if (!title) {
      return {};
    }

    const { data } = await apolloClient.query({
      query: searchMilestonesQuery,
      variables: { fullPath, isProject: !isGroup, search: title },
    });

    const milestones = data?.group?.milestones?.nodes ?? data?.project?.milestones?.nodes ?? [];
    const milestone = milestones.find((node) => node.title === title);
    return milestone ? { [WIDGET_TYPE_MILESTONE]: { milestone } } : {};
  },
};

export const FILTER_INHERITORS = [labelsInheritor, assigneesInheritor, milestoneInheritor];
