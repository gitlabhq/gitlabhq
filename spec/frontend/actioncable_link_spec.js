import { print } from 'graphql';
import gql from 'graphql-tag';
import cable from '~/actioncable_consumer';
import ActionCableLink from '~/actioncable_link';

// Mock uuids module for determinism
jest.mock('~/lib/utils/uuids', () => ({
  uuids: () => ['testuuid'],
}));

const TEST_OPERATION = {
  query: gql`
    query foo {
      project {
        id
      }
    }
  `,
  operationName: 'foo',
  variables: [],
};

/**
 * Create an observer that passes calls to the given spy.
 *
 * This helps us assert which calls were made in what order.
 */
const createSpyObserver = (spy) => ({
  next: (...args) => spy('next', ...args),
  error: (...args) => spy('error', ...args),
  complete: (...args) => spy('complete', ...args),
});

const notify = (...notifications) => {
  notifications.forEach((data) => cable.subscriptions.notifyAll('received', data));
};

const getSubscriptionCount = () => cable.subscriptions.subscriptions.length;

describe('~/actioncable_link', () => {
  let cableLink;

  beforeEach(() => {
    jest.spyOn(cable.subscriptions, 'create');

    cableLink = new ActionCableLink();
  });

  describe('request', () => {
    let subscription;
    let spy;

    beforeEach(() => {
      spy = jest.fn();
      subscription = cableLink.request(TEST_OPERATION).subscribe(createSpyObserver(spy));
    });

    afterEach(() => {
      subscription.unsubscribe();
    });

    it('creates a subscription', () => {
      expect(getSubscriptionCount()).toBe(1);
      expect(cable.subscriptions.create).toHaveBeenCalledWith(
        {
          channel: 'GraphqlChannel',
          nonce: 'testuuid',
          ...TEST_OPERATION,
          query: print(TEST_OPERATION.query),
        },
        { received: expect.any(Function) },
      );
    });

    it('when "unsubscribe", unsubscribes underlying cable subscription', () => {
      subscription.unsubscribe();

      expect(getSubscriptionCount()).toBe(0);
    });

    it('when receives data, triggers observer until no ".more"', () => {
      notify(
        { result: 'test result', more: true },
        { result: 'test result 2', more: true },
        { result: 'test result 3' },
        { result: 'test result 4' },
      );

      expect(spy.mock.calls).toEqual([
        ['next', 'test result'],
        ['next', 'test result 2'],
        ['next', 'test result 3'],
        ['complete'],
      ]);
    });

    it('when receives errors, triggers observer', () => {
      notify(
        { result: 'test result', more: true },
        { result: 'test result 2', errors: ['boom!'], more: true },
        { result: 'test result 3' },
      );

      expect(spy.mock.calls).toEqual([
        ['next', 'test result'],
        ['error', ['boom!']],
      ]);
    });
  });
});
