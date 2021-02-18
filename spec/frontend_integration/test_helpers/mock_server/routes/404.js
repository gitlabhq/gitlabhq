import { Response } from 'miragejs';

export default (server) => {
  ['get', 'post', 'put', 'delete', 'patch'].forEach((method) => {
    server[method]('*', () => {
      return new Response(404);
    });
  });
};
