import VueApollo from 'vue-apollo';
import { defaultClient } from './issuable_default_client';

/**
 * The work item Apollo provider.
 *
 * The client it wraps lives in `./issuable_default_client`, which is on
 * `INFECTION_BLOCKLIST`, so every Vue lane reads and writes one cache. The provider
 * cannot be shared the same way: `vue-apollo` resolves to a different package per
 * lane, so a provider built for Vue 2 does not work in a Vue 3 app. Each lane
 * therefore builds its own provider around that one client.
 *
 * Import `defaultClient` when you need the cache, and `apolloProvider` only when you
 * mount a Vue app.
 *
 * https://gitlab.com/gitlab-org/gitlab/-/work_items/625296
 */
export const apolloProvider = new VueApollo({
  defaultClient,
});

export { config, resolvers, defaultClient } from './issuable_default_client';
