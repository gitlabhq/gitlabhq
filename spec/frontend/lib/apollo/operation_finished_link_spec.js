import { ApolloLink, Observable, execute } from '@apollo/client/core';
import { testApolloLink } from 'helpers/test_apollo_link';
import { getOperationFinishedLink } from '~/lib/apollo/operation_finished_link';

describe('getOperationFinishedLink', () => {
  let subscription;
  let startedSpy;
  let finishedSpy;
  let calls = [];

  beforeEach(() => {
    calls = [];

    startedSpy = jest.fn().mockImplementation(() => {
      calls.push('started');
    });
    finishedSpy = jest.fn().mockImplementation(() => {
      calls.push('finished');
    });
  });

  afterEach(() => {
    subscription?.unsubscribe();
  });

  const createSubscription = (link, observer) => {
    const mockOperation = { operationName: 'testOperation' };
    subscription = execute(link, mockOperation).subscribe(observer);
  };

  it('returns an ApolloLink', () => {
    expect(getOperationFinishedLink()).toEqual(expect.any(ApolloLink));
  });

  it('creates link when no callbacks provided', async () => {
    const link = getOperationFinishedLink();
    await testApolloLink(link);

    expect(calls).toEqual([]);
  });

  it('does not throw when started callback is not provided', async () => {
    const link = getOperationFinishedLink({ finished: finishedSpy });
    await testApolloLink(link);

    expect(calls).toEqual(['finished']);
  });

  it('does not throw when finished callback is not provided', async () => {
    const link = getOperationFinishedLink({ started: startedSpy });
    await testApolloLink(link);

    expect(calls).toEqual(['started']);
  });

  describe('successful operations', () => {
    it('calls callbacks in correct order', async () => {
      const link = getOperationFinishedLink({ started: startedSpy, finished: finishedSpy });
      await testApolloLink(link);

      expect(calls).toEqual(['started', 'finished']);

      expect(startedSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          operationName: 'getFooQuery',
        }),
      );
      expect(finishedSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          operationName: 'getFooQuery',
        }),
      );
    });

    it('forwards the result data correctly', async () => {
      const link = getOperationFinishedLink({ started: startedSpy, finished: finishedSpy });
      const linksWithSuccess = link.concat(
        new ApolloLink(() => Observable.of({ data: { user: 'John Doe' } })),
      );

      await new Promise((resolve) => {
        createSubscription(linksWithSuccess, {
          next: ({ data }) => {
            expect(data).toEqual({ user: 'John Doe' });
          },
          complete: () => {
            resolve();
          },
        });
      });

      expect(calls).toEqual(['started', 'finished']);
    });
  });

  describe('error operations', () => {
    it('calls finished callback when operation errors', async () => {
      const errorLink = new ApolloLink(
        () =>
          new Observable((observer) => {
            observer.error(new Error('An error!'));
          }),
      );
      const link = getOperationFinishedLink({ started: startedSpy, finished: finishedSpy });
      const linksWithError = link.concat(errorLink);

      await new Promise((resolve) => {
        createSubscription(linksWithError, {
          next: () => {
            throw new Error('Should not be called');
          },
          error: (error) => {
            expect(error).toEqual(new Error('An error!'));
            resolve();
          },
        });
      });

      expect(calls).toEqual(['started', 'finished']);
    });
  });

  describe('subscription cleanup', () => {
    it('properly cleans up the subscription', () => {
      const unsubscribeSpy = jest.fn();
      const mockLink = new ApolloLink(() => {
        return new Observable(() => {
          return unsubscribeSpy;
        });
      });

      const link = getOperationFinishedLink({ started: startedSpy, finished: finishedSpy }).concat(
        mockLink,
      );
      const mockOperation = { operationName: 'test' };

      subscription = execute(link, mockOperation).subscribe({});
      subscription.unsubscribe();

      expect(unsubscribeSpy).toHaveBeenCalled();
    });
  });
});
