import { ApolloLink, execute, Observable } from '@apollo/client/core';
import { correlationIdLink } from '~/lib/apollo/correlation_id_link';

describe('getCorrelationIdLink', () => {
  let subscription;
  const mockCorrelationId = 'abc123';
  const mockData = { foo: { id: 1 } };

  afterEach(() => subscription?.unsubscribe());

  const makeMockTerminatingLink = () =>
    new ApolloLink(() =>
      Observable.of({
        data: mockData,
      }),
    );

  const createSubscription = (link, observer, headerName) => {
    const mockOperation = {
      operationName: 'someMockOperation',
      context: {
        response: {
          headers: {
            get: (name) => (name === headerName ? mockCorrelationId : null),
          },
        },
      },
    };
    subscription = execute(link, mockOperation).subscribe(observer);
  };

  describe.each(['X-Request-Id', 'x-request-id'])('when header name is %s', (headerName) => {
    let link;
    beforeEach(() => {
      link = correlationIdLink.concat(makeMockTerminatingLink());
    });

    it('adds the correlation ID to the response', () => {
      return new Promise((resolve) => {
        createSubscription(
          link,
          ({ correlationId }) => {
            expect(correlationId).toBe(mockCorrelationId);
            resolve();
          },
          headerName,
        );
      });
    });

    it('does not modify the original response', () => {
      return new Promise((resolve) => {
        createSubscription(
          link,
          (response) => {
            expect(response.data).toEqual(mockData);
            resolve();
          },
          headerName,
        );
      });
    });
  });
});
