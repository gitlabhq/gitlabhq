import { createMockServer } from '../mock_server';

beforeEach(() => {
  const server = createMockServer();
  server.logging = false;

  global.mockServer = server;
});

afterEach(() => {
  global.mockServer.shutdown();
  global.mockServer = null;
});
