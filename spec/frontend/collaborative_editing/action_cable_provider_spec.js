import * as Y from 'yjs';
import { Awareness, encodeAwarenessUpdate, removeAwarenessStates } from 'y-protocols/awareness';
import cable from '~/actioncable_consumer';
import ActionCableProvider from '~/collaborative_editing/action_cable_provider';
import { bytesToBase64 } from '~/collaborative_editing/encoding';
import { logError } from '~/lib/logger';

jest.mock('~/lib/logger');

describe('collaborative_editing/action_cable_provider', () => {
  const channelParams = { container_full_path: 'group/project', slug: 'home' };
  const identity = { id: 7, name: 'Aardvark', avatarUrl: '/avatar.png' };

  let provider;
  let subscription;
  let callbacks;

  const createProvider = () => {
    provider = new ActionCableProvider({
      channel: 'CollaborativeEditing::WikiPageChannel',
      channelParams,
    });
  };

  const connectAndInit = ({ updates = [], seed = false } = {}) => {
    provider.connect();
    callbacks.connected();
    callbacks.received({ type: 'init', updates, seed });
  };

  const sentMessages = (type) =>
    subscription.send.mock.calls.map(([message]) => message).filter((m) => m.type === type);

  const decodePayload = (payload) => Uint8Array.from(atob(payload), (c) => c.charCodeAt(0));

  const documentFromAll = (...payloads) => {
    const receiver = new Y.Doc();
    payloads.forEach((payload) => Y.applyUpdate(receiver, decodePayload(payload)));

    return receiver.getText('content').toString();
  };

  const documentFrom = (payload) => documentFromAll(payload);

  const updateFrom = (text) => {
    const remote = new Y.Doc();
    remote.getText('content').insert(0, text);

    return bytesToBase64(Y.encodeStateAsUpdate(remote));
  };

  beforeEach(() => {
    subscription = { send: jest.fn(), unsubscribe: jest.fn() };

    jest.spyOn(cable.subscriptions, 'create').mockImplementation((_params, handlers) => {
      callbacks = handlers;
      return subscription;
    });

    createProvider();
  });

  afterEach(() => {
    provider.destroy();
  });

  describe('connect', () => {
    it('subscribes with the given channel and params', () => {
      provider.connect();

      expect(cable.subscriptions.create).toHaveBeenCalledWith(
        { channel: 'CollaborativeEditing::WikiPageChannel', ...channelParams },
        expect.any(Object),
      );
    });

    it('does not publish any identity of its own into the awareness state', () => {
      provider.connect();

      expect(provider.awareness.getLocalState()?.user).toBeUndefined();
    });
  });

  describe('receiving the initial state', () => {
    it('applies existing updates to the document', () => {
      connectAndInit({ updates: [updateFrom('from a peer')] });

      expect(provider.doc.getText('content').toString()).toBe('from a peer');
    });

    it('resolves whenSynced with the seed decision', async () => {
      connectAndInit({ seed: true });

      await expect(provider.whenSynced).resolves.toEqual({ seed: true });
    });

    it('does not echo the applied updates back to the server', () => {
      connectAndInit({ updates: [updateFrom('from a peer')] });

      expect(sentMessages('sync')).toHaveLength(0);
    });

    it('announces its presence once synced', () => {
      connectAndInit();

      expect(sentMessages('awareness')).not.toHaveLength(0);
    });

    it('applies the sound updates either side of a malformed one', () => {
      connectAndInit({ updates: [updateFrom('kept'), 'not base64 at all'] });

      expect(provider.doc.getText('content').toString()).toBe('kept');
      expect(logError).toHaveBeenCalled();
    });
  });

  describe('local document changes', () => {
    beforeEach(() => {
      connectAndInit();
    });

    it('sends an update the server can apply', () => {
      provider.doc.getText('content').insert(0, 'typed locally');

      const [message] = sentMessages('sync');

      expect(documentFrom(message.payload)).toBe('typed locally');
      expect(message.clientId).toBe(provider.doc.clientID);
    });

    describe('while disconnected', () => {
      beforeEach(() => {
        callbacks.disconnected();

        provider.doc.getText('content').insert(0, 'typed while offline');
      });

      it('does not send anything', () => {
        expect(sentMessages('sync')).toHaveLength(0);
      });

      it('sends full state on reconnect, because the dropped delta is unrecoverable', () => {
        callbacks.connected();

        const [resent] = sentMessages('sync');

        expect(documentFrom(resent.payload)).toBe('typed while offline');
      });

      it('returns to sending incremental updates once reconnected', () => {
        callbacks.connected();
        provider.doc.getText('content').insert(0, 'and ');

        const [, incremental] = sentMessages('sync');

        expect(documentFrom(incremental.payload)).toBe('');
      });

      it('re-arms when the connection drops again', () => {
        callbacks.connected();
        callbacks.disconnected();
        provider.doc.getText('content').insert(0, 'and ');
        callbacks.connected();

        const [, resent] = sentMessages('sync');

        expect(documentFrom(resent.payload)).toBe('and typed while offline');
      });
    });
  });

  describe('remote messages', () => {
    beforeEach(() => {
      connectAndInit();
    });

    it('applies a sync update from another client', () => {
      callbacks.received({
        type: 'sync',
        payload: updateFrom('typed elsewhere'),
        clientId: provider.doc.clientID + 1,
      });

      expect(provider.doc.getText('content').toString()).toBe('typed elsewhere');
    });

    it('ignores a message echoed back from itself', () => {
      callbacks.received({
        type: 'sync',
        payload: updateFrom('echo'),
        clientId: provider.doc.clientID,
      });

      expect(provider.doc.getText('content').toString()).toBe('');
    });

    it('ignores an unrecognised message type', () => {
      expect(() => callbacks.received({ type: 'nonsense' })).not.toThrow();
    });

    describe('with a malformed payload', () => {
      const receiveMalformed = (type) =>
        callbacks.received({
          type,
          payload: 'not base64 at all',
          clientId: provider.doc.clientID + 1,
        });

      it.each(['sync', 'awareness'])('discards a %s payload it cannot apply', (type) => {
        expect(() => receiveMalformed(type)).not.toThrow();
        expect(logError).toHaveBeenCalled();
      });

      it('keeps relaying local changes afterwards', () => {
        receiveMalformed('sync');

        provider.doc.getText('content').insert(0, 'still working');

        expect(sentMessages('sync')).toHaveLength(1);
      });
    });
  });

  describe('compaction', () => {
    beforeEach(() => {
      connectAndInit();
    });

    it('sends a snapshot of the whole document, carrying the token back', () => {
      provider.doc.getText('content').insert(0, 'the full document');

      callbacks.received({ type: 'request_snapshot', token: 'a-compaction-token' });

      const [message] = sentMessages('snapshot');

      expect(documentFrom(message.payload)).toBe('the full document');
      expect(message.token).toBe('a-compaction-token');
    });

    it('sends no snapshot without a token, because the server would reject it', () => {
      provider.doc.getText('content').insert(0, 'the full document');

      callbacks.received({ type: 'request_snapshot' });

      expect(sentMessages('snapshot')).toHaveLength(0);
    });
  });

  describe('when the server reports the document is full', () => {
    beforeEach(() => {
      connectAndInit();

      provider.doc.getText('content').insert(0, 'dropped by the server');
      callbacks.received({ type: 'document_full' });
    });

    it('replaces the dropped update by sending full state on the next change', () => {
      provider.doc.getText('content').insert(0, 'and ');

      const [, resent] = sentMessages('sync');

      expect(documentFrom(resent.payload)).toBe('and dropped by the server');
    });

    it('returns to sending incremental updates once full state has landed', () => {
      provider.doc.getText('content').insert(0, 'and ');
      provider.doc.getText('content').insert(0, 'so ');

      const [, fullState, incremental] = sentMessages('sync');

      expect(documentFrom(incremental.payload)).toBe('');
      expect(documentFromAll(fullState.payload, incremental.payload)).toBe(
        'so and dropped by the server',
      );
    });

    it('does not resend full state when a snapshot already carried it', () => {
      callbacks.received({ type: 'request_snapshot', token: 'a-compaction-token' });

      provider.doc.getText('content').insert(0, 'and ');

      const [snapshot] = sentMessages('snapshot');
      const [, incremental] = sentMessages('sync');

      expect(documentFrom(incremental.payload)).toBe('');
      expect(documentFromAll(snapshot.payload, incremental.payload)).toBe(
        'and dropped by the server',
      );
    });

    it('still resends full state when the snapshot could not be sent', () => {
      callbacks.disconnected();
      callbacks.received({ type: 'request_snapshot', token: 'a-compaction-token' });
      callbacks.connected();

      const [, resent] = sentMessages('sync');

      expect(documentFrom(resent.payload)).toBe('dropped by the server');
    });
  });

  describe('identityFor', () => {
    const remoteClientId = 42;

    const receiveAwareness = ({ user } = {}) => {
      const remoteDoc = new Y.Doc();
      remoteDoc.clientID = remoteClientId;
      const remoteAwareness = new Awareness(remoteDoc);
      remoteAwareness.setLocalStateField('cursor', null);

      callbacks.received({
        type: 'awareness',
        payload: bytesToBase64(encodeAwarenessUpdate(remoteAwareness, [remoteClientId])),
        clientId: remoteClientId,
        user,
      });

      remoteAwareness.destroy();
    };

    beforeEach(() => {
      connectAndInit();
    });

    it('returns null for a client that has not been seen', () => {
      expect(provider.identityFor(remoteClientId)).toBeNull();
    });

    it('records the identity the server stamped on an awareness relay', () => {
      receiveAwareness({ user: identity });

      expect(provider.identityFor(remoteClientId)).toEqual(identity);
    });

    it('returns null when the server stamped no identity', () => {
      receiveAwareness();

      expect(provider.identityFor(remoteClientId)).toBeNull();
    });

    it('forgets the identity once the client leaves', () => {
      receiveAwareness({ user: identity });

      removeAwarenessStates(provider.awareness, [remoteClientId], null);

      expect(provider.identityFor(remoteClientId)).toBeNull();
    });
  });

  describe('when the subscription is rejected', () => {
    beforeEach(() => {
      provider.connect();
      callbacks.rejected();
    });

    it('logs the rejection', () => {
      expect(logError).toHaveBeenCalled();
    });

    it('resolves whenSynced so the editor still loads its content', async () => {
      await expect(provider.whenSynced).resolves.toEqual({ seed: true });
    });
  });

  describe('seed', () => {
    beforeEach(() => {
      connectAndInit({ seed: true });
    });

    it('produces identical updates whichever client seeds', async () => {
      const other = new ActionCableProvider({ channel: 'c', channelParams });

      await provider.seed(() => provider.doc.getText('content').insert(0, 'seeded'));
      await other.seed(() => other.doc.getText('content').insert(0, 'seeded'));

      expect(Y.encodeStateAsUpdate(other.doc)).toEqual(Y.encodeStateAsUpdate(provider.doc));

      other.destroy();
    });

    it('converges rather than duplicating when two clients both seed', async () => {
      const other = new ActionCableProvider({ channel: 'c', channelParams });

      await provider.seed(() => provider.doc.getText('content').insert(0, 'seeded'));
      await other.seed(() => other.doc.getText('content').insert(0, 'seeded'));

      Y.applyUpdate(provider.doc, Y.encodeStateAsUpdate(other.doc));

      expect(provider.doc.getText('content').toString()).toBe('seeded');

      other.destroy();
    });

    it('restores the original clientID afterwards', async () => {
      const { clientID } = provider.doc;

      await provider.seed(() => {});

      expect(provider.doc.clientID).toBe(clientID);
    });

    it('restores the original clientID when seeding throws', async () => {
      const { clientID } = provider.doc;

      await expect(
        provider.seed(() => {
          throw new Error('deserialization failed');
        }),
      ).rejects.toThrow('deserialization failed');

      expect(provider.doc.clientID).toBe(clientID);
    });
  });

  describe('destroy', () => {
    it('unsubscribes so the WebSocket does not stay open', () => {
      connectAndInit();

      provider.destroy();

      expect(subscription.unsubscribe).toHaveBeenCalled();
    });

    it('can be called twice', () => {
      connectAndInit();

      provider.destroy();

      expect(() => provider.destroy()).not.toThrow();
    });
  });
});
