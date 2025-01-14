import { Response } from 'miragejs';
import emojis from 'public/-/emojis/4/emojis.json';
import { EMOJI_VERSION } from '~/emoji';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

export default (server) => {
  server.get(`/-/emojis/${EMOJI_VERSION}/emojis.json`, () => {
    return new Response(HTTP_STATUS_OK, {}, emojis);
  });
};
