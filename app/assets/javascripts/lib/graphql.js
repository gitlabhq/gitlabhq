import { ApolloClient } from 'apollo-client';
import { InMemoryCache } from 'apollo-cache-inmemory';
import { createUploadLink } from 'apollo-upload-client';
import csrf from '~/lib/utils/csrf';

export default (resolvers = {}, baseUrl = '') => {
  let uri = `${gon.relative_url_root}/api/graphql`;

  if (baseUrl) {
    // Prepend baseUrl and ensure that `///` are replaced with `/`
    uri = `${baseUrl}${uri}`.replace(/\/{3,}/g, '/');
  }

  return new ApolloClient({
    link: createUploadLink({
      uri,
      headers: {
        [csrf.headerKey]: csrf.token,
      },
    }),
    cache: new InMemoryCache(),
    resolvers,
  });
};
