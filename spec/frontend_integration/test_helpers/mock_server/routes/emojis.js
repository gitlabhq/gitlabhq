import { Response } from 'miragejs';
import emojis from 'public/-/emojis/2/emojis.json';
import { EMOJI_VERSION } from '~/emoji';

export default (server) => {
  server.get(`/-/emojis/${EMOJI_VERSION}/emojis.json`, () => {
    return new Response(200, {}, emojis);
  });
};
