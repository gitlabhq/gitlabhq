import { setupServer } from 'msw/node';
import {
  buildHandlers,
  featureHandlers,
  restEndpoints,
} from 'ee_else_ce_jest/msw_integration/handlers';

// Setup requests interception in Node
export const server = setupServer(...buildHandlers(featureHandlers, restEndpoints));
