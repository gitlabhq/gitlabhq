import * as Y from 'yjs';
import { Awareness, encodeAwarenessUpdate, applyAwarenessUpdate } from 'y-protocols/awareness';
import cable from '~/actioncable_consumer';
import { logError } from '~/lib/logger';
import { bytesToBase64, base64ToBytes } from './encoding';

const MESSAGE_TYPE_AWARENESS = 'awareness';
const MESSAGE_TYPE_DOCUMENT_FULL = 'document_full';
const MESSAGE_TYPE_INIT = 'init';
const MESSAGE_TYPE_REQUEST_SNAPSHOT = 'request_snapshot';
const MESSAGE_TYPE_SNAPSHOT = 'snapshot';
const MESSAGE_TYPE_SYNC = 'sync';

const SUBSCRIPTION_REJECTED_ERROR = 'Collaborative editing subscription was rejected';
const MALFORMED_PAYLOAD_ERROR = 'Discarded a malformed collaborative editing payload';

function discardingMalformed(messageType, apply) {
  try {
    apply();
  } catch (error) {
    logError(MALFORMED_PAYLOAD_ERROR, messageType, error);
  }
}

export default class ActionCableProvider {
  static SEED_CLIENT_ID = 0;

  #docUpdateHandler;
  #awarenessUpdateHandler;
  #resolveSynced;
  #resendFullState = false;

  constructor({ channel, channelParams }) {
    this.doc = new Y.Doc();
    this.awareness = new Awareness(this.doc);
    this.channel = channel;
    this.channelParams = channelParams;
    this.identities = new Map();
    this.subscription = null;
    this.connected = false;
    this.synced = false;

    this.whenSynced = new Promise((resolve) => {
      this.#resolveSynced = resolve;
    });

    this.#docUpdateHandler = this.#onDocUpdate.bind(this);
    this.#awarenessUpdateHandler = this.#onAwarenessUpdate.bind(this);
  }

  connect() {
    this.doc.on('update', this.#docUpdateHandler);
    this.awareness.on('update', this.#awarenessUpdateHandler);

    this.subscription = cable.subscriptions.create(
      { channel: this.channel, ...this.channelParams },
      {
        connected: () => {
          this.connected = true;
          this.#flushFullState();
        },
        disconnected: () => {
          this.connected = false;
        },
        rejected: () => {
          logError(SUBSCRIPTION_REJECTED_ERROR);
          this.#markSynced({ seed: true });
        },
        received: (message) => this.#onMessage(message),
      },
    );
  }

  async seed(populate) {
    const { clientID } = this.doc;
    this.doc.clientID = ActionCableProvider.SEED_CLIENT_ID;

    try {
      await populate();
    } finally {
      this.doc.clientID = clientID;
    }
  }

  destroy() {
    if (this.subscription) {
      this.subscription.unsubscribe();
      this.subscription = null;
    }

    this.doc.off('update', this.#docUpdateHandler);
    this.awareness.off('update', this.#awarenessUpdateHandler);
    this.awareness.destroy();
    this.doc.destroy();
    this.identities.clear();
    this.connected = false;
  }

  identityFor(clientId) {
    return this.identities.get(clientId) ?? null;
  }

  #onMessage(message) {
    switch (message.type) {
      case MESSAGE_TYPE_INIT:
        this.#applyInitialState(message);
        break;
      case MESSAGE_TYPE_SYNC:
        this.#applyRemoteUpdate(message);
        break;
      case MESSAGE_TYPE_AWARENESS:
        this.#applyRemoteAwareness(message);
        break;
      case MESSAGE_TYPE_REQUEST_SNAPSHOT:
        this.#sendSnapshot(message.token);
        break;
      case MESSAGE_TYPE_DOCUMENT_FULL:
        this.#resendFullState = true;
        break;
      default:
        break;
    }
  }

  #applyInitialState({ updates = [], seed = false }) {
    this.doc.transact(() => {
      updates.forEach((update) => this.#applyDocUpdate(update, MESSAGE_TYPE_INIT));
    }, this);

    this.#markSynced({ seed });
  }

  #applyRemoteUpdate({ payload, clientId }) {
    if (clientId === this.doc.clientID) return;

    this.#applyDocUpdate(payload, MESSAGE_TYPE_SYNC);
  }

  #applyDocUpdate(payload, messageType) {
    discardingMalformed(messageType, () => Y.applyUpdate(this.doc, base64ToBytes(payload), this));
  }

  #applyRemoteAwareness({ payload, clientId, user }) {
    if (clientId === this.doc.clientID) return;

    if (user) {
      this.identities.set(clientId, user);
    }

    discardingMalformed(MESSAGE_TYPE_AWARENESS, () =>
      applyAwarenessUpdate(this.awareness, base64ToBytes(payload), this),
    );
  }

  #markSynced({ seed }) {
    if (this.synced) return;

    this.synced = true;
    this.#resolveSynced({ seed });

    this.#sendAwareness([this.doc.clientID]);
  }

  #onDocUpdate(update, origin) {
    if (origin === this) return;

    if (this.#resendFullState) {
      this.#flushFullState();
      return;
    }

    this.#resendFullState = !this.#send(MESSAGE_TYPE_SYNC, update);
  }

  #flushFullState() {
    if (!this.#resendFullState) return;

    this.#resendFullState = !this.#send(MESSAGE_TYPE_SYNC, Y.encodeStateAsUpdate(this.doc));
  }

  #onAwarenessUpdate({ added, updated, removed }, origin) {
    removed.forEach((clientId) => this.identities.delete(clientId));

    if (origin === this) return;

    this.#sendAwareness([...added, ...updated, ...removed]);
  }

  #sendAwareness(clientIds) {
    this.#send(MESSAGE_TYPE_AWARENESS, encodeAwarenessUpdate(this.awareness, clientIds));
  }

  #sendSnapshot(token) {
    if (!token) return;

    if (this.#send(MESSAGE_TYPE_SNAPSHOT, Y.encodeStateAsUpdate(this.doc), { token })) {
      this.#resendFullState = false;
    }
  }

  #send(type, bytes, extra = {}) {
    if (!this.connected || !this.subscription) return false;

    this.subscription.send({
      type,
      payload: bytesToBase64(bytes),
      clientId: this.doc.clientID,
      ...extra,
    });

    return true;
  }
}
