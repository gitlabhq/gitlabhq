import { ApolloLink, Observable } from '@apollo/client/core';

/**
 * Creates a pass through Apollo Link that runs functions when an operation has `started` and/or `finished`.
 *
 * It runs the `finished` portion even in cases of errors. Useful for debugging or tracking active requests.
 *
 * ```
 * const consoleLogLink = getOperationFinishedLink({
 *  started: (operation) => {
 *    console.log('operation has started');
 *  },
 *  finished: (operation) => {
 *    console.log('operation has finished');
 *  },
 * });
 * ```
 *
 * @returns An apollo link
 */
export const getOperationFinishedLink = ({ started, finished } = {}) =>
  new ApolloLink((operation, forward) => {
    return new Observable((observer) => {
      started?.(operation);

      // `finished` must run exactly once, also when the operation is
      // unsubscribed before completing, so counters cannot get stuck.
      let isFinished = false;
      const finish = () => {
        if (!isFinished) {
          isFinished = true;
          finished?.(operation);
        }
      };

      const subscription = forward(operation).subscribe({
        next: (result) => {
          observer.next(result);
        },
        error: (error) => {
          finish();
          observer.error(error);
        },
        complete: () => {
          finish();
          observer.complete();
        },
      });
      return () => {
        finish();
        subscription.unsubscribe();
      };
    });
  });
