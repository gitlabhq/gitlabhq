import { ApolloLink, Observable } from '@apollo/client/core';
import waitForPromises from 'helpers/wait_for_promises';
import { getSuppressNetworkErrorsDuringNavigationLink } from '~/lib/apollo/suppress_network_errors_during_navigation_link';
import { isNavigatingAway } from '~/lib/utils/is_navigating_away';

jest.mock('~/lib/utils/is_navigating_away');

describe('getSuppressNetworkErrorsDuringNavigationLink', () => {
  let subscription;

  afterEach(() => {
    if (subscription) {
      subscription.unsubscribe();
    }
  });

  const makeMockGraphQLErrorLink = () =>
    new ApolloLink(() =>
      Observable.of({
        errors: [
          {
            message: 'foo',
          },
        ],
      }),
    );

  const makeMockNetworkErrorLink = () =>
    new ApolloLink(
      () =>
        new Observable(() => {
          throw new Error('NetworkError');
        }),
    );

  const makeMockSuccessLink = () =>
    new ApolloLink(() => Observable.of({ data: { foo: { id: 1 } } }));

  const createSubscription = (otherLink, observer) => {
    const mockOperation = { operationName: 'foo' };
    const link = getSuppressNetworkErrorsDuringNavigationLink().concat(otherLink);
    subscription = link.request(mockOperation).subscribe(observer);
  };

  it('returns an ApolloLink', () => {
    expect(getSuppressNetworkErrorsDuringNavigationLink()).toEqual(expect.any(ApolloLink));
  });

  describe('suppression case', () => {
    describe('when navigating away', () => {
      beforeEach(() => {
        isNavigatingAway.mockReturnValue(true);
      });

      describe('given a network error', () => {
        it('does not forward the error', async () => {
          const spy = jest.fn();

          createSubscription(makeMockNetworkErrorLink(), {
            next: spy,
            error: spy,
            complete: spy,
          });

          // It's hard to test for something _not_ happening. The best we can
          // do is wait a bit to make sure nothing happens.
          await waitForPromises();
          expect(spy).not.toHaveBeenCalled();
        });
      });
    });
  });

  describe('non-suppression cases', () => {
    describe('when not navigating away', () => {
      beforeEach(() => {
        isNavigatingAway.mockReturnValue(false);
      });

      it('forwards successful requests', () => {
        createSubscription(makeMockSuccessLink(), {
          next({ data }) {
            expect(data).toEqual({ foo: { id: 1 } });
          },
          error: () => {
            throw new Error('Should not happen');
          },
        });
      });

      it('forwards GraphQL errors', () => {
        createSubscription(makeMockGraphQLErrorLink(), {
          next({ errors }) {
            expect(errors).toEqual([{ message: 'foo' }]);
          },
          error: () => {
            throw new Error('Should not happen');
          },
        });
      });

      it('forwards network errors', () => {
        createSubscription(makeMockNetworkErrorLink(), {
          next: () => {
            throw new Error('Should not happen');
          },
          error: (error) => {
            expect(error.message).toBe('NetworkError');
          },
          complete: () => {
            throw new Error('Should not happen');
          },
        });
      });
    });

    describe('when navigating away', () => {
      beforeEach(() => {
        isNavigatingAway.mockReturnValue(true);
      });

      it('forwards successful requests', () => {
        createSubscription(makeMockSuccessLink(), {
          next({ data }) {
            expect(data).toEqual({ foo: { id: 1 } });
          },
          error: () => {
            throw new Error('Should not happen');
          },
        });
      });

      it('forwards GraphQL errors', () => {
        createSubscription(makeMockGraphQLErrorLink(), {
          next({ errors }) {
            expect(errors).toEqual([{ message: 'foo' }]);
          },
          error: () => {
            throw new Error('Should not happen');
          },
        });
      });
    });
  });
});
