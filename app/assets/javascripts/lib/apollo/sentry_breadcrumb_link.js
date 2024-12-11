import { ApolloLink } from '@apollo/client/core';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

const REQUEST = 'graphql.request';
const RESPONSE = 'graphql.response';

const addGraphqlBreadcrumb = (category, data = {}) => {
  Sentry.addBreadcrumb({
    level: 'info',
    category,
    data,
  });
};

/**
 * An ApolloLink that sets a Sentry breadcrumb to make the GraphQL operation name
 * visible in a Sentry event report.
 *
 * @see https://develop.sentry.dev/sdk/data-model/event-payloads/breadcrumbs/
 * @see https://www.apollographql.com/docs/react/api/link/introduction
 */
export const sentryBreadcrumbLink = new ApolloLink((operation, forward) => {
  addGraphqlBreadcrumb(REQUEST, { operationName: operation.operationName });

  return forward(operation).map((response) => {
    addGraphqlBreadcrumb(RESPONSE, {
      correlationId: response.correlationId,
      operationName: operation.operationName,
    });

    return response;
  });
});
