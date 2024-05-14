import { ApolloLink } from '@apollo/client/core';

function getCorrelationId(operation) {
  const {
    response: { headers },
  } = operation.getContext();

  return headers?.get('X-Request-Id') || headers?.get('x-request-id');
}

/**
 * An ApolloLink used to get the correlation_id from the X-Request-Id response header.
 *
 * The correlationId is added to the response so our components can read and use it:
 * const { correlationId } = await this.$apollo.mutate({ ...
 */
export const correlationIdLink = new ApolloLink((operation, forward) =>
  forward(operation).map((response) => ({
    ...response,
    correlationId: getCorrelationId(operation),
  })),
);
