import { gql, execute, ApolloLink, Observable } from '@apollo/client/core';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

import { sentryBreadcrumbLink } from '~/lib/apollo/sentry_breadcrumb_link';

jest.mock('~/sentry/sentry_browser_wrapper');

const executeQuery = async (query, correlationId) => {
  const terminatingLink = new ApolloLink(() =>
    Observable.of({ data: { things: 1 }, correlationId }),
  );
  const mockLink = sentryBreadcrumbLink.concat(terminatingLink);

  await new Promise((resolve) => {
    execute(mockLink, { query }).subscribe(resolve);
  });
};

describe('sentryBreadcrumbLink', () => {
  describe('with a named query', () => {
    const QUERY = gql`
      query getThings {
        things
      }
    `;

    beforeEach(async () => {
      await executeQuery(QUERY, 'my-correlation-id');
    });

    it('addBreadcrumb is called', () => {
      expect(Sentry.addBreadcrumb).toHaveBeenCalledTimes(2);

      expect(Sentry.addBreadcrumb).toHaveBeenNthCalledWith(1, {
        level: 'info',
        category: 'graphql.request',
        data: {
          operationName: 'getThings',
        },
      });

      expect(Sentry.addBreadcrumb).toHaveBeenNthCalledWith(2, {
        level: 'info',
        category: 'graphql.response',
        data: {
          operationName: 'getThings',
          correlationId: 'my-correlation-id',
        },
      });
    });
  });
});
