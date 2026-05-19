/**
 * When a query uses `namespace { workItems @client { ... } }`, Apollo invokes this resolver
 * instead of sending a GraphQL network request. The resolver fetches data from the work items
 * REST endpoint and maps the response to match the GraphQL WorkItem type shape so Apollo can
 * cache it.
 *
 * REST endpoint: GET /api/:version/namespaces/:full_path/-/work_items
 */

import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';
import { convertGraphQLVarsToRestParams } from './rest_filter_params_mapper';

const WORK_ITEMS_PATH = '/api/:version/namespaces/:full_path/-/work_items';

const REST_STATE_TO_GRAPHQL = {
  opened: 'OPEN',
  closed: 'CLOSED',
  locked: 'LOCKED',
};

function mapWidgetsFromFeatures(features) {
  const widgets = [];

  const labelsData = features?.labels;
  widgets.push({
    __typename: 'WorkItemWidgetLabels',
    type: 'LABELS',
    allowsScopedLabels: labelsData?.allows_scoped_labels ?? false,
    labels: {
      nodes: (labelsData?.labels ?? []).map((label) => ({
        __typename: 'Label',
        id: label.id ? `gid://gitlab/Label/${label.id}` : null,
        title: label.title,
        color: label.color,
        textColor: label.text_color,
        description: label.description ?? null,
      })),
    },
  });

  const assignees = features?.assignees ?? [];
  widgets.push({
    __typename: 'WorkItemWidgetAssignees',
    type: 'ASSIGNEES',
    assignees: {
      nodes: assignees.map((user) => ({
        id: user.id ? `gid://gitlab/User/${user.id}` : null,
        avatarUrl: user.avatar_url ?? null,
        name: user.name,
        username: user.username,
        webUrl: user.web_url ?? null, // eslint-disable-line local-rules/no-web-url
        webPath: user.web_path ?? null,
        __typename: 'UserCore',
      })),
      __typename: 'UserCoreConnection',
    },
  });

  const milestone = features?.milestone;
  widgets.push({
    __typename: 'WorkItemWidgetMilestone',
    type: 'MILESTONE',
    milestone: milestone
      ? {
          id: milestone.id ? `gid://gitlab/Milestone/${milestone.id}` : null,
          dueDate: milestone.due_date ?? null,
          startDate: milestone.start_date ?? null,
          title: milestone.title,
          webPath: milestone.web_path ?? null,
          __typename: 'Milestone',
        }
      : null,
  });
  const startAndDueDateData = features?.start_and_due_date;
  if (startAndDueDateData) {
    widgets.push({
      __typename: 'WorkItemWidgetStartAndDueDate',
      type: 'START_AND_DUE_DATE',
      dueDate: startAndDueDateData.due_date ?? null,
      startDate: startAndDueDateData.start_date ?? null,
    });
  }

  return widgets;
}

function mapWorkItemToGraphQL(item, namespace) {
  return {
    __typename: 'WorkItem',
    id: item.global_id,
    iid: String(item.iid),
    title: item.title,
    titleHtml: item.title_html ?? item.title,
    state: REST_STATE_TO_GRAPHQL[item.state] ?? item.state,
    createdAt: item.created_at,
    updatedAt: item.updated_at,
    closedAt: item.closed_at ?? null,
    confidential: item.confidential ?? false,
    hidden: item.hidden ?? false,
    reference: item.reference ?? null,
    webPath: item.web_path ?? null,
    author: item.author
      ? {
          __typename: 'UserCore',
          id: item.author.id ? `gid://gitlab/User/${item.author.id}` : null,
          avatarUrl: item.author.avatar_url ?? null,
          name: item.author.name,
          username: item.author.username,
          webPath: item.author.web_path ?? null,
        }
      : null,
    namespace: {
      __typename: 'Namespace',
      id: namespace.id,
      fullPath: namespace.fullPath,
    },
    workItemType: item.work_item_type
      ? {
          __typename: 'WorkItemType',
          id: item.work_item_type.id
            ? `gid://gitlab/WorkItems::Type/${item.work_item_type.id}`
            : null,
          name: item.work_item_type.name,
          iconName: item.work_item_type.icon_name ?? null,
        }
      : null,
    widgets: mapWidgetsFromFeatures(item.features),
  };
}

// Parses keyset pagination info from REST API response headers
function parsePageInfo(headers) {
  const nextCursor = headers['x-next-cursor'] || null;
  const prevCursor = headers['x-prev-cursor'] || null;
  return {
    __typename: 'PageInfo',
    hasNextPage: Boolean(nextCursor),
    hasPreviousPage: Boolean(prevCursor),
    endCursor: nextCursor,
    startCursor: prevCursor,
  };
}

export async function workItemsRestResolver(namespace, args) {
  const { fullPath } = namespace;

  const restParams = convertGraphQLVarsToRestParams(args);

  restParams.set(
    'fields',
    'id,iid,global_id,title,title_html,state,created_at,updated_at,closed_at,reference,web_path,author,work_item_type,confidential,hidden',
  );
  restParams.set('features', 'labels,assignees,milestone,start_and_due_date');

  const url = buildApiUrl(WORK_ITEMS_PATH).replace(':full_path', encodeURIComponent(fullPath));

  let response;
  try {
    response = await axios.get(url, { params: restParams });
  } catch (error) {
    Sentry.captureException(error);
    throw error;
  }

  const nodes = (response.data ?? []).map((item) => mapWorkItemToGraphQL(item, namespace));
  const pageInfo = parsePageInfo(response.headers);
  return {
    __typename: 'WorkItemConnection',
    pageInfo,
    nodes,
  };
}
