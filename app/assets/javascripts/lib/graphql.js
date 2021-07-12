import { InMemoryCache } from 'apollo-cache-inmemory';
import { ApolloClient } from 'apollo-client';
import { ApolloLink } from 'apollo-link';
import { BatchHttpLink } from 'apollo-link-batch-http';
import { HttpLink } from 'apollo-link-http';
import { createUploadLink } from 'apollo-upload-client';
import ActionCableLink from '~/actioncable_link';
import { apolloCaptchaLink } from '~/captcha/apollo_captcha_link';
import { StartupJSLink } from '~/lib/utils/apollo_startup_js_link';
import csrf from '~/lib/utils/csrf';
import { objectToQuery, queryToObject } from '~/lib/utils/url_utility';
import PerformanceBarService from '~/performance_bar/services/performance_bar_service';

export const fetchPolicies = {
  CACHE_FIRST: 'cache-first',
  CACHE_AND_NETWORK: 'cache-and-network',
  NETWORK_ONLY: 'network-only',
  NO_CACHE: 'no-cache',
  CACHE_ONLY: 'cache-only',
};

export const stripWhitespaceFromQuery = (url, path) => {
  /* eslint-disable-next-line no-unused-vars */
  const [_, params] = url.split(path);

  if (!params) {
    return url;
  }

  const decoded = decodeURIComponent(params);
  const paramsObj = queryToObject(decoded);

  if (!paramsObj.query) {
    return url;
  }

  const stripped = paramsObj.query
    .split(/\s+|\n/)
    .join(' ')
    .trim();
  paramsObj.query = stripped;

  const reassembled = objectToQuery(paramsObj);
  return `${path}?${reassembled}`;
};

export default (resolvers = {}, config = {}) => {
  const {
    assumeImmutableResults,
    baseUrl,
    batchMax = 10,
    cacheConfig,
    fetchPolicy = fetchPolicies.CACHE_FIRST,
    typeDefs,
    path = '/api/graphql',
    useGet = false,
  } = config;
  let uri = `${gon.relative_url_root || ''}${path}`;

  if (baseUrl) {
    // Prepend baseUrl and ensure that `///` are replaced with `/`
    uri = `${baseUrl}${uri}`.replace(/\/{3,}/g, '/');
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
    batchMax,
  };

  const requestCounterLink = new ApolloLink((operation, forward) => {
    window.pendingApolloRequests = window.pendingApolloRequests || 0;
    window.pendingApolloRequests += 1;

    return forward(operation).map((response) => {
      window.pendingApolloRequests -= 1;
      return response;
    });
  });

  /*
    This custom fetcher intervention is to deal with an issue where we are using GET to access
    eTag polling, but Apollo Client adds excessive whitespace, which causes the
    request to fail on certain self-hosted stacks. When we can move
    to subscriptions entirely or can land an upstream PR, this can be removed.

    Related links
    Bug report: https://gitlab.com/gitlab-org/gitlab/-/issues/329895
    Moving to subscriptions: https://gitlab.com/gitlab-org/gitlab/-/issues/332485
    Apollo Client issue: https://github.com/apollographql/apollo-feature-requests/issues/182
  */

  const fetchIntervention = (url, options) => {
    return fetch(stripWhitespaceFromQuery(url, path), options);
  };

  const requestLink = ApolloLink.split(
    () => useGet,
    new HttpLink({ ...httpOptions, fetch: fetchIntervention }),
    new BatchHttpLink(httpOptions),
  );

  const uploadsLink = ApolloLink.split(
    (operation) => operation.getContext().hasUpload || operation.getContext().isSingleRequest,
    createUploadLink(httpOptions),
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

  const hasSubscriptionOperation = ({ query: { definitions } }) => {
    return definitions.some(
      ({ kind, operation }) => kind === 'OperationDefinition' && operation === 'subscription',
    );
  };

  const appLink = ApolloLink.split(
    hasSubscriptionOperation,
    new ActionCableLink(),
    ApolloLink.from([
      requestCounterLink,
      performanceBarLink,
      new StartupJSLink(),
      apolloCaptchaLink,
      uploadsLink,
      requestLink,
    ]),
  );

  return new ApolloClient({
    typeDefs,
    link: appLink,
    cache: new InMemoryCache({
      ...cacheConfig,
      freezeResults: assumeImmutableResults,
    }),
    resolvers,
    assumeImmutableResults,
    defaultOptions: {
      query: {
        fetchPolicy,
      },
    },
  });
};
