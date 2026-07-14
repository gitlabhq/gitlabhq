import { fetch, Request, Response, Headers } from '@whatwg-node/fetch';
import { configure } from '@testing-library/vue';
import {
  clearMissingOperations,
  missingOperations,
  resetCapturedRequests,
} from 'jest/msw_integration/operation_helpers';
import { server } from './server';
import { setupRouter } from './setup_utils';
import { baseMetadata } from './constants';
import * as testHelpers from './test_helpers';
import * as workItemsTestHelpers from './work_items/test_helpers';

jest.mock('~/actioncable_consumer', () => ({
  __esModule: true,
  default: {
    subscriptions: {
      create: jest.fn(() => ({
        unsubscribe: jest.fn(),
        perform: jest.fn(),
      })),
    },
  },
}));

global.fetch = fetch;
global.Request = Request;
global.Response = Response;
global.Headers = Headers;
global.metadata = baseMetadata;

// Import all test helpers as global utilities
Object.assign(global, testHelpers);
Object.assign(global, workItemsTestHelpers);

// Under CI load a starved worker can blow @testing-library's 1000ms waitFor
// default; 3s gives headroom and stays under the suite's testTimeout.
configure({ asyncUtilTimeout: 3000 });

beforeAll(() => {
  server.listen({ onUnhandledRequest: 'warn' });
});

beforeEach(async () => {
  const { router } = global.metadata;
  if (router) {
    await setupRouter(router);
  }

  window.gon = { ...window.gon, current_user_id: 16 };
});

afterEach(() => {
  server.resetHandlers();
  global.metadata = baseMetadata;
  resetCapturedRequests();
});

afterAll(() => {
  // `server.close()` must run even if the missing-handler warning throws (the
  // ConsoleWatcher turns it into a synchronous throw). Otherwise the MSW server
  // leaks, the worker never exits, and Jest hangs until --forceExit masks the run.
  try {
    if (missingOperations.size > 0) {
      // eslint-disable-next-line no-console
      console.warn(
        `Test suite is missing graphql handlers for operations: ${Array.from(missingOperations, (el) => `\n - ${el}`)}\n\nSee https://docs.gitlab.com/ee/development/testing_guide/frontend_testing/#write-feature-handlers`,
      );
      clearMissingOperations();
    }
  } finally {
    server.close();
  }
});
