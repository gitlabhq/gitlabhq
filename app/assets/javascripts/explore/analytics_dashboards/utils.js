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
