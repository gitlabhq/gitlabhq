import { fetch, Request, Response, Headers } from '@whatwg-node/fetch';
import { server } from './server';

global.fetch = fetch;
global.Request = Request;
global.Response = Response;
global.Headers = Headers;

beforeAll(() => {
  server.listen({ onUnhandledRequest: 'warn' });
});

beforeEach(() => {});

afterEach(() => {
  server.resetHandlers();
});

afterAll(() => server.close());
