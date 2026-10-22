import * as Y from 'yjs';
import {
  Awareness,
  encodeAwarenessUpdate,
  applyAwarenessUpdate,
  removeAwarenessStates,
} from 'y-protocols/awareness';
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

  const acknowledge = (message) =>
    callbacks.received({ type: 'ack', messageId: message.messageId });

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
    it('does not send local changes until the initial state arrives', () => {
      provider.connect();
      callbacks.connected();
      provider.doc.getText('content').insert(0, 'before init');

      expect(sentMessages('sync')).toHaveLength(0);

      callbacks.received({ type: 'init', updates: [] });

      expect(documentFrom(sentMessages('sync')[0].payload)).toBe('before init');
    });

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

    it('does not announce awareness before the initial state arrives', () => {
      provider.connect();
      callbacks.connected();

      expect(sentMessages('awareness')).toHaveLength(0);
    });

    it('re-announces its current awareness on reconnect without waiting for a heartbeat', () => {
      connectAndInit();
      provider.awareness.setLocalStateField('cursor', { anchor: 1 });
      const peerAwareness = new Awareness(new Y.Doc());
      const [initialAnnouncement] = sentMessages('awareness').slice(-1);
      applyAwarenessUpdate(peerAwareness, decodePayload(initialAnnouncement.payload), null);
      removeAwarenessStates(peerAwareness, [provider.doc.clientID], null);
      subscription.send.mockClear();
      callbacks.disconnected();

      callbacks.connected();

      const [announcement] = sentMessages('awareness');
      expect(sentMessages('awareness')).toHaveLength(1);

      applyAwarenessUpdate(peerAwareness, decodePayload(announcement.payload), null);

      expect(peerAwareness.getStates().get(provider.doc.clientID)).toMatchObject({
        cursor: { anchor: 1 },
      });
      peerAwareness.destroy();
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
        callbacks.received({ type: 'init', updates: [] });

        const [resent] = sentMessages('sync');

        expect(documentFrom(resent.payload)).toBe('typed while offline');
      });

      it('sends offline edits when init arrives before the connected callback', () => {
        callbacks.received({ type: 'init', updates: [] });
        expect(sentMessages('sync')).toHaveLength(0);

        callbacks.connected();

        expect(documentFrom(sentMessages('sync')[0].payload)).toBe('typed while offline');
      });

      it('returns to sending incremental updates once reconnected', () => {
        callbacks.connected();
        callbacks.received({ type: 'init', updates: [] });
        acknowledge(sentMessages('sync')[0]);
        provider.doc.getText('content').insert(0, 'and ');

        const [, incremental] = sentMessages('sync');

        expect(documentFrom(incremental.payload)).toBe('');
      });

      it('re-arms when the connection drops again', () => {
        callbacks.connected();
        callbacks.received({ type: 'init', updates: [] });
        callbacks.disconnected();
        provider.doc.getText('content').insert(0, 'and ');
        callbacks.connected();
        callbacks.received({ type: 'init', updates: [] });

        const [, resent] = sentMessages('sync');

        expect(documentFrom(resent.payload)).toBe('and typed while offline');
      });
    });

    describe('while awaiting server acknowledgement', () => {
      beforeEach(() => {
        provider.doc.getText('content').insert(0, 'first');
      });

      it('merges queued edits without sending the whole document after acknowledgement', () => {
        provider.doc.getText('content').insert(5, ' second');
        const [first] = sentMessages('sync');
        expect(sentMessages('sync')).toHaveLength(1);

        acknowledge(first);
        const [, merged] = sentMessages('sync');
        expect(documentFrom(merged.payload)).toBe('');
        expect(documentFromAll(first.payload, merged.payload)).toBe('first second');

        provider.doc.getText('content').insert(12, ' third');
        expect(sentMessages('sync')).toHaveLength(2);

        acknowledge(merged);
        expect(documentFrom(sentMessages('sync')[2].payload)).toBe('');
        expect(
          documentFromAll(first.payload, merged.payload, sentMessages('sync')[2].payload),
        ).toBe('first second third');
      });

      it('combines several queued edits into a single incremental update', () => {
        provider.doc.getText('content').insert(5, ' second');
        provider.doc.getText('content').insert(12, ' third');
        const [first] = sentMessages('sync');

        acknowledge(first);

        const [, merged] = sentMessages('sync');
        expect(sentMessages('sync')).toHaveLength(2);
        expect(documentFrom(merged.payload)).toBe('');
        expect(documentFromAll(first.payload, merged.payload)).toBe('first second third');
      });

      it('returns to incremental updates after the queued edits are acknowledged', () => {
        provider.doc.getText('content').insert(5, ' second');
        acknowledge(sentMessages('sync')[0]);
        acknowledge(sentMessages('sync')[1]);
        provider.doc.getText('content').insert(12, ' third');

        expect(documentFrom(sentMessages('sync')[2].payload)).toBe('');
      });

      it('returns to incremental updates after the first update is acknowledged', () => {
        acknowledge(sentMessages('sync')[0]);
        provider.doc.getText('content').insert(5, ' second');

        expect(documentFrom(sentMessages('sync')[1].payload)).toBe('');
      });

      it('does not accept an acknowledgement without the pending message ID', () => {
        callbacks.received({ type: 'ack' });
        provider.doc.getText('content').insert(5, ' second');

        expect(sentMessages('sync')).toHaveLength(1);
        acknowledge(sentMessages('sync')[0]);
        expect(documentFrom(sentMessages('sync')[1].payload)).toBe('');
        expect(
          documentFromAll(sentMessages('sync')[0].payload, sentMessages('sync')[1].payload),
        ).toBe('first second');
      });

      it('resends full state on reconnect without an acknowledgement', () => {
        callbacks.disconnected();
        callbacks.connected();
        expect(sentMessages('sync')).toHaveLength(1);
        callbacks.received({ type: 'init', updates: [] });

        expect(documentFrom(sentMessages('sync')[1].payload)).toBe('first');
      });

      it('waits for init before resending edits made during reconnection', () => {
        callbacks.disconnected();
        callbacks.connected();
        provider.doc.getText('content').insert(5, ' second');

        expect(sentMessages('sync')).toHaveLength(1);

        callbacks.received({ type: 'init', updates: [] });

        expect(documentFrom(sentMessages('sync')[1].payload)).toBe('first second');
      });

      it('resends unacknowledged and queued edits when init precedes connected', () => {
        provider.doc.getText('content').insert(5, ' second');
        callbacks.disconnected();
        callbacks.received({ type: 'init', updates: [] });
        expect(sentMessages('sync')).toHaveLength(1);

        callbacks.connected();

        expect(documentFrom(sentMessages('sync')[1].payload)).toBe('first second');
      });

      it('retries a dropped final update without another edit', () => {
        jest.advanceTimersByTime(5000);

        expect(documentFrom(sentMessages('sync')[1].payload)).toBe('first');
      });

      it('does not send full state on every keystroke while the server is silent', () => {
        provider.doc.getText('content').insert(5, ' second');
        provider.doc.getText('content').insert(12, ' third');

        expect(sentMessages('sync')).toHaveLength(1);

        jest.advanceTimersByTime(5000);
        expect(documentFrom(sentMessages('sync')[1].payload)).toBe('first second third');
      });

      it('does not replay the same document after an acknowledgement with no later edits', () => {
        provider.doc.getText('content').insert(5, ' second');
        acknowledge(sentMessages('sync')[0]);
        acknowledge(sentMessages('sync')[1]);
        jest.advanceTimersByTime(60000);

        expect(sentMessages('sync')).toHaveLength(2);
      });

      it('keeps retrying without accepting an old acknowledgement', () => {
        const [first] = sentMessages('sync');
        jest.advanceTimersByTime(5000);
        acknowledge(first);
        jest.advanceTimersByTime(10000);

        expect(sentMessages('sync')).toHaveLength(3);
      });

      it('ignores a late acknowledgement from the previous connection', () => {
        const [first] = sentMessages('sync');
        callbacks.disconnected();
        callbacks.connected();
        callbacks.received({ type: 'init', updates: [] });
        acknowledge(first);
        jest.advanceTimersByTime(5000);

        expect(sentMessages('sync')).toHaveLength(3);
      });

      it('backs off retries while the server is silent', () => {
        jest.advanceTimersByTime(5000);
        jest.advanceTimersByTime(9999);
        expect(sentMessages('sync')).toHaveLength(2);

        jest.advanceTimersByTime(1);
        expect(sentMessages('sync')).toHaveLength(3);
      });

      it('stops retrying after acknowledgement', () => {
        acknowledge(sentMessages('sync')[0]);
        jest.advanceTimersByTime(60000);

        expect(sentMessages('sync')).toHaveLength(1);
      });

      it('stops retrying while disconnected and resends after init', () => {
        callbacks.disconnected();
        jest.advanceTimersByTime(60000);
        expect(sentMessages('sync')).toHaveLength(1);

        callbacks.connected();
        callbacks.received({ type: 'init', updates: [] });

        expect(documentFrom(sentMessages('sync')[1].payload)).toBe('first');
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

    it('waits for snapshot acknowledgement when it supersedes an unacknowledged sync', () => {
      provider.doc.getText('content').insert(0, 'unsaved');
      const [sync] = sentMessages('sync');

      callbacks.received({ type: 'request_snapshot', token: 'a-compaction-token' });
      acknowledge(sync);
      provider.doc.getText('content').insert(7, ' changes');

      expect(sentMessages('sync')).toHaveLength(1);
      acknowledge(sentMessages('snapshot')[0]);
      expect(documentFrom(sentMessages('sync')[1].payload)).toBe('');
      expect(
        documentFromAll(sentMessages('snapshot')[0].payload, sentMessages('sync')[1].payload),
      ).toBe('unsaved changes');

      acknowledge(sentMessages('sync')[1]);
      provider.doc.getText('content').insert(15, ' more');

      expect(documentFrom(sentMessages('sync')[2].payload)).toBe('');
    });
  });

  describe('when the server reports the document is full', () => {
    beforeEach(() => {
      connectAndInit();

      provider.doc.getText('content').insert(0, 'dropped by the server');
      callbacks.received({ type: 'document_full', messageId: sentMessages('sync')[0].messageId });
    });

    it('replaces the dropped update on retry, including later edits', () => {
      provider.doc.getText('content').insert(0, 'and ');
      jest.advanceTimersByTime(5000);

      const [, resent] = sentMessages('sync');

      expect(documentFrom(resent.payload)).toBe('and dropped by the server');
    });

    it('retries a rejected final update even without another edit', () => {
      jest.advanceTimersByTime(5000);

      expect(documentFrom(sentMessages('sync')[1].payload)).toBe('dropped by the server');
    });

    it('waits for the armed retry when editing a full document', () => {
      provider.doc.getText('content').insert(0, 'and ');

      expect(sentMessages('sync')).toHaveLength(1);
      jest.advanceTimersByTime(4999);
      expect(sentMessages('sync')).toHaveLength(1);
      jest.advanceTimersByTime(1);

      expect(documentFrom(sentMessages('sync')[1].payload)).toBe('and dropped by the server');
    });

    it('backs off repeated document-full rejections and resets after acknowledgement', () => {
      jest.advanceTimersByTime(4999);
      expect(sentMessages('sync')).toHaveLength(1);
      jest.advanceTimersByTime(1);
      expect(sentMessages('sync')).toHaveLength(2);

      callbacks.received({ type: 'document_full', messageId: sentMessages('sync')[1].messageId });
      jest.advanceTimersByTime(9999);
      expect(sentMessages('sync')).toHaveLength(2);
      jest.advanceTimersByTime(1);
      expect(sentMessages('sync')).toHaveLength(3);

      acknowledge(sentMessages('sync')[2]);
      provider.doc.getText('content').insert(0, 'and ');
      jest.advanceTimersByTime(5000);

      expect(sentMessages('sync')).toHaveLength(5);
    });

    it('caps repeated document-full retries at sixty seconds', () => {
      for (const delay of [5000, 10000, 20000, 40000, 60000, 60000]) {
        jest.advanceTimersByTime(delay);
        callbacks.received({
          type: 'document_full',
          messageId: sentMessages('sync').at(-1).messageId,
        });
      }

      jest.advanceTimersByTime(59999);
      expect(sentMessages('sync')).toHaveLength(7);
      jest.advanceTimersByTime(1);
      expect(sentMessages('sync')).toHaveLength(8);
    });

    it('returns to sending incremental updates once full state has landed', () => {
      provider.doc.getText('content').insert(0, 'and ');
      jest.advanceTimersByTime(5000);
      acknowledge(sentMessages('sync')[1]);
      provider.doc.getText('content').insert(0, 'so ');

      const [, fullState, incremental] = sentMessages('sync');

      expect(documentFrom(incremental.payload)).toBe('');
      expect(documentFromAll(fullState.payload, incremental.payload)).toBe(
        'so and dropped by the server',
      );
    });

    it('ignores a late rejection for an earlier update after a newer one is accepted', () => {
      const [first] = sentMessages('sync');
      jest.advanceTimersByTime(5000);
      const [, retry] = sentMessages('sync');

      callbacks.received({ type: 'document_full', messageId: first.messageId });
      acknowledge(retry);
      jest.advanceTimersByTime(60000);

      expect(sentMessages('sync')).toHaveLength(2);
    });

    it('does not cancel a pending retry when an old rejection arrives late', () => {
      const [first] = sentMessages('sync');
      jest.advanceTimersByTime(5000);

      callbacks.received({ type: 'document_full', messageId: first.messageId });
      jest.advanceTimersByTime(10000);

      expect(sentMessages('sync')).toHaveLength(3);
    });

    it('does not resend full state when a snapshot already carried it', () => {
      callbacks.received({ type: 'request_snapshot', token: 'a-compaction-token' });
      acknowledge(sentMessages('snapshot')[0]);

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
      callbacks.received({ type: 'init', updates: [] });

      const [, resent] = sentMessages('sync');

      expect(documentFrom(resent.payload)).toBe('dropped by the server');
    });
  });

  describe('when an update is rejected with queued edits', () => {
    beforeEach(() => {
      connectAndInit();
      provider.doc.getText('content').insert(0, 'dropped by the server');
      provider.doc.getText('content').insert(0, 'and ');
    });

    it('recovers both the rejected update and queued edits as full state', () => {
      expect(sentMessages('sync')).toHaveLength(1);

      callbacks.received({ type: 'document_full', messageId: sentMessages('sync')[0].messageId });
      jest.advanceTimersByTime(5000);

      expect(documentFrom(sentMessages('sync')[1].payload)).toBe('and dropped by the server');
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
    it('clears a pending retry when the editor closes', () => {
      connectAndInit();
      provider.doc.getText('content').insert(0, 'unsaved');

      provider.destroy();
      jest.advanceTimersByTime(60000);

      expect(sentMessages('sync')).toHaveLength(1);
    });

    it('announces departure before unsubscribing', () => {
      connectAndInit();
      provider.awareness.setLocalStateField('cursor', { anchor: 1 });
      const peerAwareness = new Awareness(new Y.Doc());
      const [initialAnnouncement] = sentMessages('awareness').slice(-1);
      applyAwarenessUpdate(peerAwareness, decodePayload(initialAnnouncement.payload), null);
      expect(peerAwareness.getStates().has(provider.doc.clientID)).toBe(true);
      subscription.send.mockClear();

      provider.destroy();

      expect(sentMessages('awareness')).toHaveLength(1);
      expect(subscription.send.mock.invocationCallOrder[0]).toBeLessThan(
        subscription.unsubscribe.mock.invocationCallOrder[0],
      );

      const [departure] = sentMessages('awareness');
      applyAwarenessUpdate(peerAwareness, decodePayload(departure.payload), null);

      expect(peerAwareness.getStates().has(provider.doc.clientID)).toBe(false);
      peerAwareness.destroy();
    });

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
