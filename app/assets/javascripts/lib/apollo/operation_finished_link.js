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
    started?.(operation);

    return new Observable((observer) => {
      const subscription = forward(operation).subscribe({
        next: (result) => {
          observer.next(result);
        },
        error: (error) => {
          finished?.(operation);
          observer.error(error);
        },
        complete: () => {
          finished?.(operation);
          observer.complete();
        },
      });
      return () => {
        subscription.unsubscribe();
      };
    });
  });
