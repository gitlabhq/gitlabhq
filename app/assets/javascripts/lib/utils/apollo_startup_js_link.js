import { ApolloLink, Observable } from '@apollo/client/core';
import { parse } from 'graphql';
import { isEqual, pickBy } from 'lodash';

/**
 * Remove undefined values from object
 * @param obj
 * @returns {Dictionary<unknown>}
 */
const pickDefinedValues = (obj) => pickBy(obj, (x) => x !== undefined);

/**
 * Compares two set of variables, order independent
 *
 * Ignores undefined values (in the top level) and supports arrays etc.
 */
const variablesMatch = (var1 = {}, var2 = {}) => {
  return isEqual(pickDefinedValues(var1), pickDefinedValues(var2));
};

export class StartupJSLink extends ApolloLink {
  constructor() {
    super();
    this.startupCalls = new Map();
    this.parseStartupCalls(window.gl?.startup_graphql_calls || []);
  }

  // Extract operationNames from the queries and ensure that we can
  // match operationName => element from result array
  parseStartupCalls(calls) {
    calls.forEach((call) => {
      const { query, variables, fetchCall } = call;
      const operationName = parse(query)?.definitions?.find((x) => x.kind === 'OperationDefinition')
        ?.name?.value;

      if (operationName) {
        this.startupCalls.set(operationName, {
          variables,
          fetchCall,
        });
      }
    });
  }

  static noopRequest = (operation, forward) => forward(operation);

  disable() {
    this.request = StartupJSLink.noopRequest;
    this.startupCalls = null;
  }

  request(operation, forward) {
    // Disable StartupJSLink in case all calls are done or none are set up
    if (this.startupCalls && this.startupCalls.size === 0) {
      this.disable();
      return forward(operation);
    }

    const { operationName } = operation;

    // Skip startup call if the operationName doesn't match
    if (!this.startupCalls.has(operationName)) {
      return forward(operation);
    }

    const { variables: startupVariables, fetchCall } = this.startupCalls.get(operationName);
    this.startupCalls.delete(operationName);

    // Skip startup call if the variables values do not match
    if (!variablesMatch(startupVariables, operation.variables)) {
      return forward(operation);
    }

    return new Observable((observer) => {
      fetchCall
        .then((response) => {
          // Handle HTTP errors
          if (!response.ok) {
            throw new Error('fetchCall failed');
          }
          operation.setContext({ response });
          return response.json();
        })
        .then((result) => {
          if (result && (result.errors || !result.data)) {
            throw new Error('Received GraphQL error');
          }

          // we have data and can send it to back up the link chain
          observer.next(result);
          observer.complete();
        })
        .catch(() => {
          forward(operation).subscribe({
            next: (result) => {
              observer.next(result);
            },
            error: (error) => {
              observer.error(error);
            },
            complete: observer.complete.bind(observer),
          });
        });
    });
  }
}
