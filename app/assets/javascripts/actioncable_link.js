import { ApolloLink, Observable } from '@apollo/client/core';
import { print } from 'graphql';
import cable from '~/actioncable_consumer';
import { uuids } from '~/lib/utils/uuids';

export default class ActionCableLink extends ApolloLink {
  // eslint-disable-next-line class-methods-use-this
  request(operation) {
    return new Observable((observer) => {
      const subscription = cable.subscriptions.create(
        {
          channel: 'GraphqlChannel',
          query: operation.query ? print(operation.query) : null,
          variables: operation.variables,
          operationName: operation.operationName,
          nonce: uuids()[0],
        },
        {
          received(data) {
            if (data.errors) {
              observer.error(data.errors);
            } else if (data.result) {
              observer.next(data.result);
            }

            if (!data.more) {
              observer.complete();
            }
          },
        },
      );

      return {
        unsubscribe() {
          subscription.unsubscribe();
        },
      };
    });
  }
}
