import { createMockServer } from '../mock_server';

beforeEach(() => {
  if (global.mockServer) {
    global.mockServer.shutdown();
  }

  const server = createMockServer();
  server.logging = false;
  server.pretender.handledRequest = (verb, path, { status, responseText }) => {
    if (status >= 500) {
      // eslint-disable-next-line no-console
      console.log(`
The mock server returned status ${status} with "${verb} ${path}":

${JSON.stringify({ responseText }, null, 2)}
`);
    }
  };

  global.mockServer = server;
});
