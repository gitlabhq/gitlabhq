import { fetch, Request, Response, Headers } from '@whatwg-node/fetch';
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
});

afterAll(() => server.close());
