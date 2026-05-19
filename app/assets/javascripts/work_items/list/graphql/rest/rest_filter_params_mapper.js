/**
 * Maps GraphQL query variables (as used in planning_view.vue) to REST API query params
 * for the work items list endpoint: GET /api/:version/namespaces/:full_path/-/work_items
 */

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
  POPULARITY_ASC: { order_by: 'upvotes', sort: 'asc' },
  POPULARITY_DESC: { order_by: 'upvotes', sort: 'desc' },
  CLOSED_AT_ASC: { order_by: 'closed_at', sort: 'asc' },
  CLOSED_AT_DESC: { order_by: 'closed_at', sort: 'desc' },
};

const STATE_MAP = {
  OPENED: 'opened',
  CLOSED: 'closed',
  ALL: 'all',
};

// eslint-disable-next-line @gitlab/require-i18n-strings
const WILDCARD_MAP = { ANY: 'Any', NONE: 'None', UPCOMING: 'Upcoming', STARTED: 'Started' };

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

// Appends nested filter params in Rails bracket notation, e.g. not[label_name][], or[author_username]
function appendNestedFilterParams(params, prefix, filters) {
  if (!filters) return;

  Object.entries(filters).forEach(([key, value]) => {
    if (value === null || value === undefined) return;

    const restKey = key.replace(/([A-Z])/g, (letter) => `_${letter.toLowerCase()}`);

    if (Array.isArray(value)) {
      value.forEach((v) => params.append(`${prefix}[${restKey}][]`, v));
    } else {
      params.append(`${prefix}[${restKey}]`, value);
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

  appendParam(params, 'cursor', vars.after ?? vars.afterCursor);
  appendParam(params, 'per_page', vars.first ?? vars.firstPageSize);
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

  if (vars.types?.length) {
    const typesArray = Array.isArray(vars.types) ? vars.types : [vars.types];
    typesArray.forEach((t) => appendParam(params, 'types[]', t.toLowerCase()));
  }

  appendParam(params, 'crm_contact_id', vars.crmContactId);
  appendParam(params, 'crm_organization_id', vars.crmOrganizationId);
  appendParam(params, 'release_tag', vars.releaseTag);
  appendParam(params, 'release_tag_wildcard_id', WILDCARD_MAP[vars.releaseTagWildcardId]);

  if (vars.hierarchyFilters?.parentId) {
    appendParam(params, 'parent_ids[]', vars.hierarchyFilters.parentId);
  }

  if (vars.includeDescendants !== undefined) {
    appendParam(params, 'include_descendants', vars.includeDescendants);
  }

  appendNestedFilterParams(params, 'not', vars.not);
  appendNestedFilterParams(params, 'or', vars.or);

  return params;
}
