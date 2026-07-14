/**
 * Maps GraphQL query variables (as used in planning_view.vue) to REST API query params
 * for the work items list endpoint: GET /api/:version/namespaces/:full_path/-/work_items
 */

import { getIdFromGraphQLId } from '~/graphql_shared/utils';

const GRAPHQL_SORT_TO_REST = {
  CREATED_ASC: { order_by: 'created_at', sort: 'asc' },
  CREATED_DESC: { order_by: 'created_at', sort: 'desc' },
  UPDATED_ASC: { order_by: 'updated_at', sort: 'asc' },
  UPDATED_DESC: { order_by: 'updated_at', sort: 'desc' },
  TITLE_ASC: { order_by: 'title', sort: 'asc' },
  TITLE_DESC: { order_by: 'title', sort: 'desc' },
  RELATIVE_POSITION_ASC: { order_by: 'relative_position', sort: 'asc' },
  PRIORITY_ASC: { order_by: 'priority', sort: 'asc' },
  PRIORITY_DESC: { order_by: 'priority', sort: 'desc' },
  POPULARITY_ASC: { order_by: 'popularity', sort: 'asc' },
  POPULARITY_DESC: { order_by: 'popularity', sort: 'desc' },
  CLOSED_AT_ASC: { order_by: 'closed_at', sort: 'asc' },
  CLOSED_AT_DESC: { order_by: 'closed_at', sort: 'desc' },
  DUE_DATE_ASC: { order_by: 'due_date', sort: 'asc' },
  DUE_DATE_DESC: { order_by: 'due_date', sort: 'desc' },
  START_DATE_ASC: { order_by: 'start_date', sort: 'asc' },
  START_DATE_DESC: { order_by: 'start_date', sort: 'desc' },
  LABEL_PRIORITY_ASC: { order_by: 'label_priority', sort: 'asc' },
  LABEL_PRIORITY_DESC: { order_by: 'label_priority', sort: 'desc' },
  BLOCKING_ISSUES_ASC: { order_by: 'blocking_issues', sort: 'asc' },
  BLOCKING_ISSUES_DESC: { order_by: 'blocking_issues', sort: 'desc' },
  HEALTH_STATUS_ASC: { order_by: 'health_status', sort: 'asc' },
  HEALTH_STATUS_DESC: { order_by: 'health_status', sort: 'desc' },
  WEIGHT_ASC: { order_by: 'weight', sort: 'asc' },
  WEIGHT_DESC: { order_by: 'weight', sort: 'desc' },
  MILESTONE_DUE_ASC: { order_by: 'milestone_due', sort: 'asc' },
  MILESTONE_DUE_DESC: { order_by: 'milestone_due', sort: 'desc' },
};

const STATE_MAP = {
  OPENED: 'opened',
  CLOSED: 'closed',
  ALL: 'all',
};

/* eslint-disable @gitlab/require-i18n-strings -- REST API param values, not user-facing text */
const WILDCARD_MAP = {
  ANY: 'Any',
  NONE: 'None',
  ME: 'Me',
  UPCOMING: 'Upcoming',
  STARTED: 'Started',
};
/* eslint-enable @gitlab/require-i18n-strings */

const SEARCH_IN_MAP = {
  TITLE: 'title',
  DESCRIPTION: 'description',
};

function appendParam(params, key, value) {
  if (value === null || value === undefined) return;
  if (Array.isArray(value)) {
    value.forEach((v) => {
      if (v !== null && v !== undefined) params.append(`${key}[]`, v);
    });
  } else {
    params.append(key, value);
  }
}

function appendWorkItemTypeIds(params, key, gids) {
  const values = Array.isArray(gids) ? gids : [gids];
  values.forEach((gid) => {
    const numericId = getIdFromGraphQLId(gid);
    if (numericId) params.append(key, numericId);
  });
}

// Appends nested filter params in Rails bracket notation, e.g. not[label_name][], or[author_username]
function appendNestedFilterParams(params, prefix, filters) {
  if (!filters) return;

  Object.entries(filters).forEach(([key, value]) => {
    if (value === null || value === undefined) return;

    const restKey = key.replace(/([A-Z])/g, (letter) => `_${letter.toLowerCase()}`);

    // Special handling for fields that need numeric IDs extracted from GIDs
    if (restKey === 'work_item_type_ids' || restKey === 'parent_ids') {
      appendWorkItemTypeIds(params, `${prefix}[${restKey}][]`, value);
    } else if (restKey === 'milestone_wildcard_id') {
      params.append(`${prefix}[${restKey}]`, WILDCARD_MAP[value] ?? value);
    } else {
      const paramKey = Array.isArray(value) ? `${prefix}[${restKey}][]` : `${prefix}[${restKey}]`;
      if (Array.isArray(value)) {
        value.forEach((v) => {
          if (v !== null && v !== undefined) params.append(paramKey, v);
        });
      } else {
        params.append(paramKey, value);
      }
    }
  });
}

export function convertGraphQLVarsToRestParams(vars) {
  const params = new URLSearchParams();

  if (vars.state) {
    appendParam(params, 'state', STATE_MAP[vars.state] ?? vars.state.toLowerCase());
  }

  if (vars.sort) {
    const restSort = GRAPHQL_SORT_TO_REST[vars.sort];
    if (restSort) {
      appendParam(params, 'order_by', restSort.order_by);
      appendParam(params, 'sort', restSort.sort);
    }
  }

  // Handle pagination: support both cursor-based and page-based pagination
  const cursorValue = vars.after ?? vars.afterCursor ?? vars.before ?? vars.beforeCursor;
  if (cursorValue) {
    if (/^\d+$/.test(cursorValue)) {
      appendParam(params, 'page', cursorValue);
    } else {
      appendParam(params, 'cursor', cursorValue);
    }
  }

  appendParam(
    params,
    'per_page',
    vars.first ?? vars.firstPageSize ?? vars.last ?? vars.lastPageSize,
  );
  appendParam(params, 'search', vars.search);

  if (vars.in) {
    appendParam(params, 'in', SEARCH_IN_MAP[vars.in] ?? vars.in.toLowerCase());
  }

  if (vars.iid) {
    appendParam(params, 'iids[]', vars.iid);
  }

  appendParam(params, 'assignee_usernames', vars.assigneeUsernames);
  appendParam(params, 'assignee_wildcard_id', WILDCARD_MAP[vars.assigneeWildcardId]);
  appendParam(params, 'author_username', vars.authorUsername);
  appendParam(params, 'label_name', vars.labelName);
  appendParam(params, 'milestone_title', vars.milestoneTitle);
  appendParam(params, 'milestone_wildcard_id', WILDCARD_MAP[vars.milestoneWildcardId]);
  appendParam(params, 'my_reaction_emoji', vars.myReactionEmoji);
  appendParam(params, 'subscribed', vars.subscribed);

  if (vars.confidential !== undefined && vars.confidential !== null) {
    appendParam(params, 'confidential', vars.confidential);
  }

  appendParam(params, 'created_after', vars.createdAfter);
  appendParam(params, 'created_before', vars.createdBefore);
  appendParam(params, 'updated_after', vars.updatedAfter);
  appendParam(params, 'updated_before', vars.updatedBefore);
  appendParam(params, 'closed_after', vars.closedAfter);
  appendParam(params, 'closed_before', vars.closedBefore);
  appendParam(params, 'due_after', vars.dueAfter);
  appendParam(params, 'due_before', vars.dueBefore);

  if (vars.workItemTypeIds) {
    appendWorkItemTypeIds(params, 'work_item_type_ids[]', vars.workItemTypeIds);
  }

  appendParam(params, 'crm_contact_id', vars.crmContactId);
  appendParam(params, 'crm_organization_id', vars.crmOrganizationId);
  appendParam(params, 'release_tag', vars.releaseTag);
  appendParam(params, 'release_tag_wildcard_id', WILDCARD_MAP[vars.releaseTagWildcardId]);

  if (vars.hierarchyFilters?.parentIds) {
    appendWorkItemTypeIds(params, 'parent_ids[]', vars.hierarchyFilters.parentIds);
  }

  if (vars.hierarchyFilters?.parentWildcardId) {
    appendParam(params, 'parent_wildcard_id', WILDCARD_MAP[vars.hierarchyFilters.parentWildcardId]);
  }

  if (vars.hierarchyFilters?.includeDescendantWorkItems !== undefined) {
    appendParam(
      params,
      'include_descendant_work_items',
      vars.hierarchyFilters.includeDescendantWorkItems,
    );
  }

  if (vars.includeDescendants !== undefined) {
    appendParam(params, 'include_descendants', vars.includeDescendants);
  }

  appendNestedFilterParams(params, 'not', vars.not);
  appendNestedFilterParams(params, 'or', vars.or);

  return params;
}
