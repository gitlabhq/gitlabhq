import { ApolloClient } from 'apollo-client';
import { InMemoryCache } from 'apollo-cache-inmemory';
import { createUploadLink } from 'apollo-upload-client';
import { ApolloLink } from 'apollo-link';
import { BatchHttpLink } from 'apollo-link-batch-http';
import csrf from '~/lib/utils/csrf';
import PerformanceBarService from '~/performance_bar/services/performance_bar_service';
import { StartupJSLink } from '~/lib/utils/apollo_startup_js_link';

export const fetchPolicies = {
  CACHE_FIRST: 'cache-first',
  CACHE_AND_NETWORK: 'cache-and-network',
  NETWORK_ONLY: 'network-only',
  NO_CACHE: 'no-cache',
  CACHE_ONLY: 'cache-only',
};

export default (resolvers = {}, config = {}) => {
  let uri = `${gon.relative_url_root || ''}/api/graphql`;

  if (config.baseUrl) {
    // Prepend baseUrl and ensure that `///` are replaced with `/`
    uri = `${config.baseUrl}${uri}`.replace(/\/{3,}/g, '/');
  }

  const httpOptions = {
    uri,
    headers: {
      [csrf.headerKey]: csrf.token,
    },
    // fetch won’t send cookies in older browsers, unless you set the credentials init option.
    // We set to `same-origin` which is default value in modern browsers.
    // See https://github.com/whatwg/fetch/pull/585 for more information.
    credentials: 'same-origin',
    batchMax: config.batchMax || 10,
  };

  const uploadsLink = ApolloLink.split(
    operation => operation.getContext().hasUpload || operation.getContext().isSingleRequest,
    createUploadLink(httpOptions),
    new BatchHttpLink(httpOptions),
  );

  const performanceBarLink = new ApolloLink((operation, forward) => {
    return forward(operation).map(response => {
      const httpResponse = operation.getContext().response;

      if (PerformanceBarService.interceptor) {
        PerformanceBarService.interceptor({
          config: {
            url: httpResponse.url,
          },
          headers: {
            'x-request-id': httpResponse.headers.get('x-request-id'),
            'x-gitlab-from-cache': httpResponse.headers.get('x-gitlab-from-cache'),
          },
        });
      }

      return response;
    });
  });

  return new ApolloClient({
    typeDefs: config.typeDefs,
    link: ApolloLink.from([performanceBarLink, new StartupJSLink(), uploadsLink]),
    cache: new InMemoryCache({
      ...config.cacheConfig,
      freezeResults: config.assumeImmutableResults,
    }),
    resolvers,
    assumeImmutableResults: config.assumeImmutableResults,
    defaultOptions: {
      query: {
        fetchPolicy: config.fetchPolicy || fetchPolicies.CACHE_FIRST,
      },
    },
  });
};
