import { uniqueId } from 'lodash-es';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_ANALYTICS_CUSTOM_DASHBOARD } from '~/graphql_shared/constants';

export const getUniquePanelId = () => uniqueId('panel-');

/**
 * Extracts the numeric database ID from an Analytics Custom Dashboard GraphQL global ID.
 *
 * @param {string} gid - A GraphQL global ID, e.g. "gid://gitlab/Analytics::CustomDashboards::Dashboard/3"
 * @returns {number} The numeric ID
 */
export const getDashboardIdFromGraphQLId = (gid) =>
  getIdFromGraphQLId(gid, TYPENAME_ANALYTICS_CUSTOM_DASHBOARD);

/**
 * Converts a numeric database ID to an Analytics Custom Dashboard GraphQL global ID.
 *
 * @param {string|number} id - The numeric database ID
 * @returns {string} A GraphQL global ID, e.g. "gid://gitlab/Analytics::CustomDashboards::Dashboard/3"
 */
export const convertToDashboardGraphQLId = (id) =>
  convertToGraphQLId(TYPENAME_ANALYTICS_CUSTOM_DASHBOARD, id);

/**
 * Builds the document title for a route from its breadcrumb metadata.
 *
 * The breadcrumb trail is reversed (deepest segment first) and prepended to the
 * server-rendered base title, e.g. "Edit · My dashboard · Analytics dashboards · GitLab".
 * Empty segments are dropped so the base title is used as-is while a dashboard is still loading.
 *
 * @param {object} route - The current Vue Router route
 * @param {string} baseTitle - The server-rendered document title
 * @returns {string} The composed document title
 */
export const buildDocumentTitle = (route, baseTitle) => {
  if (route.meta.root) return baseTitle;

  // Only the edit route declares parents.
  const parents = route.meta.getParents?.() ?? [];
  const name = route.meta.getName?.() ?? '';
  const segments = [name, ...parents.map(({ text }) => text).reverse()];

  return [...segments, baseTitle].filter(Boolean).join(' · ');
};
