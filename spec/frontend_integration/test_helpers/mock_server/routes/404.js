import { Response } from 'miragejs';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';

export default (server) => {
  ['get', 'post', 'put', 'delete', 'patch'].forEach((method) => {
    server[method]('*', () => {
      return new Response(HTTP_STATUS_NOT_FOUND);
    });
  });
};
