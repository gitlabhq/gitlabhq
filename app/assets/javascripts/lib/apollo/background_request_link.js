import { ApolloLink } from '@apollo/client/core';
import { BACKGROUND_REQUEST_HEADER, isUserIdle } from '~/lib/utils/user_activity';

export const backgroundRequestLink = new ApolloLink((operation, forward) => {
  if (isUserIdle()) {
    operation.setContext(({ headers }) => ({
      headers: { ...headers, [BACKGROUND_REQUEST_HEADER]: '1' },
    }));
  }

  return forward(operation);
});
