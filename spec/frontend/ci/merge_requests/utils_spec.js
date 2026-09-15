import {
  alertableFailedRequests,
  createSubscriptionsCollection,
  dismissedCreationAlertsStorageKey,
  hasAlertableFailureCountIncreased,
  nextDismissedCreationRequestIds,
} from '~/ci/merge_requests/utils';
import {
  DISMISSED_CREATION_ALERTS_LIMIT,
  DISMISSED_CREATION_ALERTS_STORAGE_KEY_BASE,
} from '~/ci/merge_requests/constants';

describe('ci merge_requests utils', () => {
  describe('alertableFailedRequests', () => {
    const failed = { id: 'uuid-1', status: 'FAILED', userInitiated: true };
    const automaticFailed = { id: 'uuid-2', status: 'FAILED', userInitiated: false };
    const succeeded = { id: 'uuid-3', status: 'SUCCEEDED', userInitiated: true };
    const nullIdFailed = { id: null, status: 'FAILED', userInitiated: true };

    it('returns user-initiated failed requests', () => {
      expect(alertableFailedRequests([failed, succeeded])).toEqual([failed]);
    });

    it('excludes automatic (not user-initiated) failed requests', () => {
      expect(alertableFailedRequests([failed, automaticFailed])).toEqual([failed]);
    });

    it('excludes dismissed request ids', () => {
      expect(alertableFailedRequests([failed], ['uuid-1'])).toEqual([]);
    });

    it('includes failed requests without an id', () => {
      expect(alertableFailedRequests([nullIdFailed], ['uuid-1'])).toEqual([nullIdFailed]);
    });

    it('treats a missing userInitiated field as user-initiated', () => {
      const legacyRequest = { id: 'uuid-4', status: 'FAILED' };

      expect(alertableFailedRequests([legacyRequest])).toEqual([legacyRequest]);
    });

    it('returns an empty array when called without arguments', () => {
      expect(alertableFailedRequests()).toEqual([]);
    });
  });

  describe('dismissedCreationAlertsStorageKey', () => {
    it('scopes the key to the project path and merge request id', () => {
      expect(dismissedCreationAlertsStorageKey('group/project', 42)).toBe(
        `${DISMISSED_CREATION_ALERTS_STORAGE_KEY_BASE}_group/project_42`,
      );
    });
  });

  describe('hasAlertableFailureCountIncreased', () => {
    const failed = { id: 'uuid-1', status: 'FAILED', userInitiated: true };
    const failed2 = { id: 'uuid-2', status: 'FAILED', userInitiated: true };
    const automaticFailed = { id: 'uuid-3', status: 'FAILED', userInitiated: false };

    it('is true when a new alertable failure appears', () => {
      expect(hasAlertableFailureCountIncreased([failed], [failed, failed2])).toBe(true);
    });

    it('is false when the alertable count is unchanged', () => {
      expect(hasAlertableFailureCountIncreased([failed], [failed])).toBe(false);
    });

    it('ignores dismissed ids on both sides', () => {
      expect(hasAlertableFailureCountIncreased([failed], [failed, failed2], ['uuid-2'])).toBe(
        false,
      );
    });

    it('does not count automatic failures', () => {
      expect(hasAlertableFailureCountIncreased([failed], [failed, automaticFailed])).toBe(false);
    });
  });

  describe('nextDismissedCreationRequestIds', () => {
    const failed = { id: 'uuid-1', status: 'FAILED', userInitiated: true };
    const nullIdFailed = { id: null, status: 'FAILED', userInitiated: true };

    it('appends alertable failed request ids to the dismissed list', () => {
      expect(nextDismissedCreationRequestIds([failed], [])).toEqual(['uuid-1']);
    });

    it('returns the existing list unchanged when nothing is alertable', () => {
      const dismissed = ['uuid-1'];

      expect(nextDismissedCreationRequestIds([failed], dismissed)).toBe(dismissed);
    });

    it('does not persist failed requests without an id', () => {
      expect(nextDismissedCreationRequestIds([nullIdFailed], [])).toEqual([]);
    });

    it('caps the list at the most recent DISMISSED_CREATION_ALERTS_LIMIT ids', () => {
      const existing = Array.from(
        { length: DISMISSED_CREATION_ALERTS_LIMIT },
        (_, i) => `old-${i}`,
      );

      const result = nextDismissedCreationRequestIds([failed], existing);

      expect(result).toHaveLength(DISMISSED_CREATION_ALERTS_LIMIT);
      expect(result[result.length - 1]).toBe('uuid-1');
      expect(result).not.toContain('old-0');
    });
  });

  describe('createSubscriptionsCollection', () => {
    let collection;
    let unsubscribeMocks;
    let factory;

    beforeEach(() => {
      unsubscribeMocks = new Map();
      factory = jest.fn((id) => {
        const unsubscribe = jest.fn();
        unsubscribeMocks.set(id, unsubscribe);
        return unsubscribe;
      });
      collection = createSubscriptionsCollection();
    });

    describe('syncSubscriptions', () => {
      it('subscribes to every id when there are no existing subscriptions', () => {
        collection.syncSubscriptions(['1', '2'], factory);

        expect(factory).toHaveBeenCalledTimes(2);
        expect(factory).toHaveBeenCalledWith('1');
        expect(factory).toHaveBeenCalledWith('2');
      });

      it('does not resubscribe to ids that are already subscribed', () => {
        collection.syncSubscriptions(['1', '2'], factory);
        factory.mockClear();

        collection.syncSubscriptions(['1', '2'], factory);

        expect(factory).not.toHaveBeenCalled();
      });

      it('subscribes only to newly added ids', () => {
        collection.syncSubscriptions(['1'], factory);
        factory.mockClear();

        collection.syncSubscriptions(['1', '2'], factory);

        expect(factory).toHaveBeenCalledTimes(1);
        expect(factory).toHaveBeenCalledWith('2');
      });

      it('unsubscribes from ids that are no longer desired', () => {
        collection.syncSubscriptions(['1', '2'], factory);

        collection.syncSubscriptions(['1'], factory);

        expect(unsubscribeMocks.get('2')).toHaveBeenCalledTimes(1);
        expect(unsubscribeMocks.get('1')).not.toHaveBeenCalled();
      });

      it('resubscribes to an id that was removed and then desired again', () => {
        collection.syncSubscriptions(['1'], factory);

        collection.syncSubscriptions([], factory);
        factory.mockClear();

        collection.syncSubscriptions(['1'], factory);

        expect(factory).toHaveBeenCalledTimes(1);
        expect(factory).toHaveBeenCalledWith('1');
      });

      it('unsubscribes from all ids when synced with an empty list', () => {
        collection.syncSubscriptions(['1', '2'], factory);

        collection.syncSubscriptions([], factory);

        expect(unsubscribeMocks.get('1')).toHaveBeenCalledTimes(1);
        expect(unsubscribeMocks.get('2')).toHaveBeenCalledTimes(1);
      });
    });

    describe('unsubscribeAll', () => {
      it('unsubscribes from every current subscription', () => {
        collection.syncSubscriptions(['1', '2'], factory);

        collection.unsubscribeAll();

        expect(unsubscribeMocks.get('1')).toHaveBeenCalledTimes(1);
        expect(unsubscribeMocks.get('2')).toHaveBeenCalledTimes(1);
      });

      it('clears the collection so a subsequent sync resubscribes', () => {
        collection.syncSubscriptions(['1'], factory);
        collection.unsubscribeAll();
        factory.mockClear();

        collection.syncSubscriptions(['1'], factory);

        expect(factory).toHaveBeenCalledTimes(1);
        expect(factory).toHaveBeenCalledWith('1');
      });

      it('does not throw when there are no subscriptions', () => {
        expect(() => collection.unsubscribeAll()).not.toThrow();
      });
    });
  });
});
