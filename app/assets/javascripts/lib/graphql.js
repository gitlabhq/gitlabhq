import { ApolloClient } from 'apollo-client';
import { InMemoryCache } from 'apollo-cache-inmemory';
import { createUploadLink } from 'apollo-upload-client';
import csrf from '~/lib/utils/csrf';

export default (resolvers = {}) =>
  new ApolloClient({
    link: createUploadLink({
      uri: `${gon.relative_url_root}/api/graphql`,
      headers: {
        [csrf.headerKey]: csrf.token,
      },
    }),
    cache: new InMemoryCache(),
    resolvers,
  });
