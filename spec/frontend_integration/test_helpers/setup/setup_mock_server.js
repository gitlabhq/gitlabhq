import { createMockServer } from '../mock_server';

beforeEach(() => {
  if (global.mockServer) {
    global.mockServer.shutdown();
  }

  const server = createMockServer();
  server.logging = false;

  global.mockServer = server;
});
