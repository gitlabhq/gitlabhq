import { rest } from 'msw';
import { handleWorkItemOperation } from './handlers';

/**
 * Creates an MSW GraphQL resolver with custom operation overrides.
 * Falls back to default handlers for non-overridden operations.
 *
 * @param {Object} overrides - Map of operationName to response data or handler function
 * @returns {RestHandler} MSW rest handler
 *
 * @example
 * server.use(
 *   createGraphQLResolver({
 *     workItemMetadataEE: noPermissionsMetadata,
 *     getWorkItemsFullEE: (variables) => customResponse,
 *   })
 * );
 */
export function createGraphQLResolver(overrides = {}) {
  return rest.post('http://test.host/api/graphql', (req, res, ctx) => {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    const { operationName, variables } = body;

    // Check for custom override
    if (overrides[operationName]) {
      const override = overrides[operationName];
      const response = typeof override === 'function' ? override(variables) : override;
      return res(ctx.json(response));
    }

    // Fall back to default handlers
    const result = handleWorkItemOperation({ operationName, variables, res, ctx });
    if (result) return result;

    return res(ctx.status(400));
  });
}

/**
 * Creates a permissions-restricted metadata response.
 * Sets all user permissions to false and hides the new work item button.
 *
 * @param {Object} baseMetadata - The base metadata fixture to modify
 * @returns {Object} Modified metadata with no permissions
 */
export function createNoPermissionsMetadata(baseMetadata) {
  const metadata = JSON.parse(JSON.stringify(baseMetadata));
  const { userPermissions, metadata: meta } = metadata.data.namespace;

  Object.keys(userPermissions).forEach((key) => {
    if (key !== '__typename') userPermissions[key] = false;
  });
  meta.showNewWorkItem = false;

  return metadata;
}
