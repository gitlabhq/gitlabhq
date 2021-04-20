import { InMemoryCache } from 'apollo-cache-inmemory';
import { ApolloClient } from 'apollo-client';
import { ApolloLink } from 'apollo-link';
import { BatchHttpLink } from 'apollo-link-batch-http';
import { createHttpLink } from 'apollo-link-http';
import { createUploadLink } from 'apollo-upload-client';
import { apolloCaptchaLink } from '~/captcha/apollo_captcha_link';
import { StartupJSLink } from '~/lib/utils/apollo_startup_js_link';
import csrf from '~/lib/utils/csrf';
import PerformanceBarService from '~/performance_bar/services/performance_bar_service';

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

  const requestCounterLink = new ApolloLink((operation, forward) => {
    window.pendingApolloRequests = window.pendingApolloRequests || 0;
    window.pendingApolloRequests += 1;

    return forward(operation).map((response) => {
      window.pendingApolloRequests -= 1;
      return response;
    });
  });

  const uploadsLink = ApolloLink.split(
    (operation) => operation.getContext().hasUpload || operation.getContext().isSingleRequest,
    createUploadLink(httpOptions),
    config.useGet ? createHttpLink(httpOptions) : new BatchHttpLink(httpOptions),
  );

  const performanceBarLink = new ApolloLink((operation, forward) => {
    return forward(operation).map((response) => {
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
    link: ApolloLink.from([
      requestCounterLink,
      performanceBarLink,
      new StartupJSLink(),
      apolloCaptchaLink,
      uploadsLink,
    ]),
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
