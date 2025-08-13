import { getParameterByName } from '~/lib/utils/url_utility';
import WorkItemList from 'ee_else_ce/work_items/pages/work_items_list_app.vue';
import CreateWorkItem from '../pages/create_work_item.vue';
import WorkItemDetail from '../pages/work_item_root.vue';
import DesignDetail from '../components/design_management/design_preview/design_details.vue';
import { getDraftWorkItemType } from '../utils';
import {
  CREATION_CONTEXT_NEW_ROUTE,
  ROUTES,
  NAME_TO_ENUM_MAP,
  WORK_ITEM_BASE_ROUTE_MAP,
  WORK_ITEM_TYPE_ENUM_INCIDENT,
  WORK_ITEM_TYPE_ENUM_ISSUE,
} from '../constants';

function generateTypeRegex(routeMap) {
  const types = Object.keys(routeMap);
  return types.join('|');
}

/**
 * For `.params-issue-type`, the backend only returns "incident" or "issue"
 *
 * @returns {string|null}
 */
function getIssueTypeEnumFromDocument() {
  // Get type from DOM as present in app/views/projects/issues/new.html.haml
  const issueType =
    getParameterByName('issue[issue_type]') &&
    document.querySelector('.params-issue-type')?.textContent.toUpperCase().trim();

  // Check if DOM-provided type is either Incident or Issue
  if ([WORK_ITEM_TYPE_ENUM_INCIDENT, WORK_ITEM_TYPE_ENUM_ISSUE].includes(issueType)) {
    return issueType;
  }
  return null;
}

function getRoutes(fullPath) {
  const routes = [
    {
      path: `/:type(${generateTypeRegex(WORK_ITEM_BASE_ROUTE_MAP)})`,
      name: ROUTES.index,
      component: WorkItemList,
    },
    {
      path: `/:type(${generateTypeRegex(WORK_ITEM_BASE_ROUTE_MAP)})/new`,
      name: ROUTES.new,
      component: CreateWorkItem,
      props: ({ params, query }) => ({
        workItemTypeEnum:
          query.type ||
          getIssueTypeEnumFromDocument() ||
          NAME_TO_ENUM_MAP[
            getDraftWorkItemType({ fullPath, context: CREATION_CONTEXT_NEW_ROUTE })?.name
          ] ||
          WORK_ITEM_BASE_ROUTE_MAP[params.type],
      }),
    },
    {
      path: `/:type(${generateTypeRegex(WORK_ITEM_BASE_ROUTE_MAP)})/:iid`,
      name: ROUTES.workItem,
      component: WorkItemDetail,
      props: true,
      children: [
        {
          name: ROUTES.design,
          path: 'designs/:id?',
          component: DesignDetail,
          beforeEnter(to, _, next) {
            if (to.params.id) {
              if (typeof to.params.id === 'string') {
                next();
              }
            } else {
              // If no ID route to main work item view.
              // This supports design version notes with format /designs?version=##
              next({
                name: ROUTES.workItem,
                params: to.params,
                query: to.query,
              });
            }
          },
          props: ({ params: { id, iid } }) => ({ id, iid }),
        },
      ],
    },
  ];

  return routes;
}

export const routes = getRoutes;
