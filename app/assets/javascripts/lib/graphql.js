import { ApolloClient } from 'apollo-client';
import { InMemoryCache } from 'apollo-cache-inmemory';
import { createUploadLink } from 'apollo-upload-client';
import csrf from '~/lib/utils/csrf';

export default (resolvers = {}, config = {}) => {
  let uri = `${gon.relative_url_root}/api/graphql`;

  if (config.baseUrl) {
    // Prepend baseUrl and ensure that `///` are replaced with `/`
    uri = `${config.baseUrl}${uri}`.replace(/\/{3,}/g, '/');
  }

  return new ApolloClient({
    link: createUploadLink({
      uri,
      headers: {
        [csrf.headerKey]: csrf.token,
      },
    }),
    cache: new InMemoryCache(config.cacheConfig),
    resolvers,
  });
};
