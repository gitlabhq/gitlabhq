import { rest } from 'msw';
import { handleWorkItemOperation, workItemRestEndpoints } from './work_items/handlers';
import { handleAiDuoPanelOperation } from './work_items/ai_duo_panel';
import { captureRequest } from './test_helpers';

// CE-only endpoints and handlers should be added here
export const featureHandlers = [handleWorkItemOperation, handleAiDuoPanelOperation];
export const restEndpoints = [...workItemRestEndpoints];

export function buildHandlers(allFeatureHandlers, allRestEndpoints) {
  const restEndpointsHandlers = allRestEndpoints.map((endpoint) =>
    rest[endpoint.method](endpoint.path, (req, res, ctx) => {
      const operationName = endpoint.name || `REST:${endpoint.method}:${endpoint.path}`;
      captureRequest(operationName, req);

      const transforms = [ctx.json(endpoint.response)];
      if (endpoint.headers) {
        Object.entries(endpoint.headers).forEach(([key, value]) => {
          transforms.push(ctx.set(key, value));
        });
      }
      return res(...transforms);
    }),
  );

  return [
    rest.post('http://test.host/api/graphql', (req, res, ctx) => {
      const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
      const { operationName, variables } = body;

      for (const handler of allFeatureHandlers) {
        const result = handler({ operationName, variables, res, ctx });
        if (result) return result;
      }

      // eslint-disable-next-line no-console
      console.log(`No handler for operationName: ${operationName}`);
      return res(ctx.status(400));
    }),

    ...restEndpointsHandlers,

    rest.get('*', (req, res, ctx) => {
      // eslint-disable-next-line no-console
      console.log(`Unhandled url for REST endpoint: ${req.url.href}`);
      return res(ctx.status(400));
    }),
  ];
}
