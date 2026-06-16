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

const NAMESPACE_KIND_TO_TYPENAME = {
  project: 'Namespaces::ProjectNamespace',
  group: 'Namespaces::GroupNamespace',
};

function mapLabelsFeature(features) {
  const labelsData = features?.labels;
  return {
    __typename: 'WorkItemWidgetLabels',
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
  };
}

function mapAssigneesFeature(features) {
  const assignees = features?.assignees ?? [];
  return {
    __typename: 'WorkItemWidgetAssignees',
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
  };
}

function mapMilestoneFeature(features) {
  const milestone = features?.milestone;
  return {
    __typename: 'WorkItemWidgetMilestone',
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
  };
}

function mapStartAndDueDateFeature(features) {
  const startAndDueDateData = features?.start_and_due_date;
  return {
    __typename: 'WorkItemWidgetStartAndDueDate',
    dueDate: startAndDueDateData?.due_date ?? null,
    startDate: startAndDueDateData?.start_date ?? null,
  };
}

function mapHierarchyFeature(features, itemNamespace) {
  const hierarchy = features?.hierarchy;
  return {
    __typename: 'WorkItemWidgetHierarchy',
    parent: hierarchy?.parent
      ? {
          __typename: 'WorkItem',
          id: hierarchy.parent.global_id,
          iid: String(hierarchy.parent.iid),
          title: hierarchy.parent.title,
          confidential: hierarchy.parent.confidential ?? false,
          webUrl: hierarchy.parent.web_url ?? null, // eslint-disable-line local-rules/no-web-url
          namespace: itemNamespace,
          workItemType: hierarchy.parent.work_item_type
            ? {
                __typename: 'WorkItemType',
                id: hierarchy.parent.work_item_type.id
                  ? `gid://gitlab/WorkItems::Type/${hierarchy.parent.work_item_type.id}`
                  : null,
                name: hierarchy.parent.work_item_type.name,
                iconName: hierarchy.parent.work_item_type.icon_name ?? null,
              }
            : null,
        }
      : null,
  };
}

export function mapWidgetsFromFeatures(features, itemNamespace) {
  return [
    { ...mapLabelsFeature(features), type: 'LABELS' },
    { ...mapAssigneesFeature(features), type: 'ASSIGNEES' },
    { ...mapMilestoneFeature(features), type: 'MILESTONE' },
    { ...mapStartAndDueDateFeature(features), type: 'START_AND_DUE_DATE' },
    { ...mapHierarchyFeature(features, itemNamespace), type: 'HIERARCHY' },
  ];
}

export function mapFeaturesFromRestResponse(features, itemNamespace) {
  return {
    __typename: 'WorkItemFeatures',
    labels: mapLabelsFeature(features),
    assignees: mapAssigneesFeature(features),
    milestone: mapMilestoneFeature(features),
    startAndDueDate: mapStartAndDueDateFeature(features),
    hierarchy: mapHierarchyFeature(features, itemNamespace),
  };
}

// Returns a `WorkItemFeatures` placeholder whose every subfield is null. We cannot use `@skip`/`@include`
// directives inside the @client subtree. To keep widgets as the single source of truth when the
// work_item_features_field flag is off we return this shape so Apollo's selection set is satisfied with explicit nulls.
export function nullWorkItemFeatures() {
  return {
    __typename: 'WorkItemFeatures',
    labels: null,
    assignees: null,
    milestone: null,
    startAndDueDate: null,
    hierarchy: null,
  };
}

export function mapWorkItemToGraphQL(item, sharedNamespace, { useWorkItemFeatures = false } = {}) {
  const itemNamespace =
    item.namespace.full_path !== sharedNamespace.fullPath
      ? {
          __typename: 'Namespace',
          // eslint-disable-next-line @gitlab/require-i18n-strings
          id: `gid://gitlab/${NAMESPACE_KIND_TO_TYPENAME[item.namespace.kind] || 'Namespace'}/${item.namespace.id}`,
          fullPath: item.namespace.full_path,
        }
      : sharedNamespace;

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
    userDiscussionsCount: item.user_discussions_count ?? 0,
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
    namespace: itemNamespace,
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
    widgets: mapWidgetsFromFeatures(item.features, itemNamespace),
    features: useWorkItemFeatures
      ? mapFeaturesFromRestResponse(item.features, itemNamespace)
      : nullWorkItemFeatures(),
  };
}

// Parses keyset pagination info from REST API response headers
export function parsePageInfo(headers) {
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
    'id,iid,global_id,title,title_html,state,created_at,updated_at,closed_at,reference,web_path,author,work_item_type,confidential,hidden,user_discussions_count,namespace',
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

  const useWorkItemFeatures = Boolean(window.gon?.features?.workItemFeaturesField);
  const nodes = (response.data ?? []).map((item) =>
    mapWorkItemToGraphQL(item, namespace, { useWorkItemFeatures }),
  );

  const pageInfo = parsePageInfo(response.headers);
  return {
    __typename: 'WorkItemConnection',
    pageInfo,
    nodes,
  };
}
