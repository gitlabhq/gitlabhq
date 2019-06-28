import { ApolloClient } from 'apollo-client';
import { InMemoryCache } from 'apollo-cache-inmemory';
import { createUploadLink } from 'apollo-upload-client';
import { ApolloLink } from 'apollo-link';
import { BatchHttpLink } from 'apollo-link-batch-http';
import csrf from '~/lib/utils/csrf';

export default (resolvers = {}, config = {}) => {
  let uri = `${gon.relative_url_root}/api/graphql`;

  if (config.baseUrl) {
    // Prepend baseUrl and ensure that `///` are replaced with `/`
    uri = `${config.baseUrl}${uri}`.replace(/\/{3,}/g, '/');
  }

  const httpOptions = {
    uri,
    headers: {
      [csrf.headerKey]: csrf.token,
    },
  };

  return new ApolloClient({
    link: ApolloLink.split(
      operation => operation.getContext().hasUpload || operation.getContext().isSingleRequest,
      createUploadLink(httpOptions),
      new BatchHttpLink(httpOptions),
    ),
    cache: new InMemoryCache(config.cacheConfig),
    resolvers,
  });
};
