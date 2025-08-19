import { s__ } from '~/locale';

import { MESSAGE_TYPES, TIMEOUTS } from '../constants';

export class MessageValidator {
  constructor(
    allowedOrigin,
    allowedMessageType,
    {
      maxMessageAge = TIMEOUTS.MAX_MESSAGE_AGE,
      maxClockSkew = TIMEOUTS.MAX_CLOCK_SKEW,
      maxNonceHistory = 1000,
      timestampTolerance = 5000,
    } = {},
  ) {
    if (!allowedOrigin || typeof allowedOrigin !== 'string') {
      throw new Error(s__('Observability|allowedOrigin must be a non-empty string'));
    }
    if (!allowedMessageType || typeof allowedMessageType !== 'string') {
      throw new Error(s__('Observability|allowedMessageType must be a non-empty string'));
    }

    this.allowedOrigin = allowedOrigin;
    this.allowedMessageType = allowedMessageType;
    this.maxMessageAge = maxMessageAge;
    this.maxClockSkew = maxClockSkew;
    this.maxNonceHistory = maxNonceHistory;
    this.timestampTolerance = timestampTolerance;
    this.lastMessageTimestamp = 0;
    this.processedNonces = new Map();
    this.recentTimestamps = new Map();
    this.lastCleanup = 0;
  }

  validateMessage(event, expectedNonce, expectedCounter) {
    const { origin, data } = event;

    if (
      !this.validateOrigin(origin) ||
      !this.validateStructure(data) ||
      !this.validateType(data.type) ||
      !this.validateNonce(data.nonce, expectedNonce) ||
      !this.validateCounter(data.counter, expectedCounter) ||
      !this.validateTimestamp(data.timestamp)
    ) {
      return { valid: false, error: s__('Observability|Message validation failed') };
    }

    this.trackNonce(data.nonce);
    return { valid: true };
  }

  validateOrigin(origin) {
    return origin === this.allowedOrigin;
  }

  // eslint-disable-next-line class-methods-use-this
  validateStructure(data) {
    if (!data || typeof data !== 'object') {
      return false;
    }

    if (
      typeof data.type !== 'string' ||
      typeof data.timestamp !== 'number' ||
      typeof data.nonce !== 'string' ||
      typeof data.counter !== 'number'
    ) {
      return false;
    }

    if (data.nonce.length === 0) {
      return false;
    }

    if (data.counter < 0) {
      return false;
    }

    return true;
  }

  validateType(type) {
    return type === this.allowedMessageType;
  }

  validateNonce(nonce, expectedNonce) {
    if (nonce !== expectedNonce) {
      return false;
    }

    if (this.processedNonces.has(nonce)) {
      return false;
    }

    return true;
  }

  // eslint-disable-next-line class-methods-use-this
  validateCounter(counter, expectedCounter) {
    return counter === expectedCounter;
  }

  validateTimestamp(timestamp) {
    const now = Date.now();
    const messageAge = now - timestamp;

    // Reject messages that are too old
    if (messageAge > this.maxMessageAge) return false;

    // Reject messages that are too far in the future (clock skew protection)
    if (messageAge < -this.maxClockSkew) return false;

    // Reject exact duplicate timestamps
    if (this.recentTimestamps.has(timestamp)) return false;

    const isNewer = timestamp > this.lastMessageTimestamp;
    const isWithinTolerance =
      Math.abs(timestamp - this.lastMessageTimestamp) <= this.timestampTolerance;

    // Accept if it's the first message, a newer message, or an older message within the tolerance window
    const isValidSequence = this.lastMessageTimestamp === 0 || isNewer || isWithinTolerance;

    if (isValidSequence) {
      // Update last timestamp only for newer messages or first message
      if (isNewer || this.lastMessageTimestamp === 0) {
        this.lastMessageTimestamp = timestamp;
      }
      this.recentTimestamps.set(timestamp, now);
      this.cleanupOldTimestamps(now);
      return true;
    }

    return false;
  }

  cleanupOldTimestamps(now) {
    const cutoffTime = now - this.maxMessageAge;
    if (!this.lastCleanup || now - this.lastCleanup > TIMEOUTS.CLEANUP_INTERVAL) {
      for (const [timestamp] of this.recentTimestamps) {
        if (timestamp < cutoffTime) {
          this.recentTimestamps.delete(timestamp);
        } else {
          break;
        }
      }
      this.lastCleanup = now;
    }
  }

  trackNonce(nonce) {
    this.processedNonces.set(nonce, Date.now());

    while (this.processedNonces.size > this.maxNonceHistory) {
      const oldestNonce = this.processedNonces.keys().next().value;
      this.processedNonces.delete(oldestNonce);
    }
  }

  reset() {
    this.lastMessageTimestamp = 0;
    this.processedNonces.clear();
    this.recentTimestamps.clear();
    this.lastCleanup = 0;
  }

  getValidationStats() {
    return {
      lastMessageTimestamp: this.lastMessageTimestamp,
      processedNoncesCount: this.processedNonces.size,
      recentTimestampsCount: this.recentTimestamps.size,
      allowedOrigin: this.allowedOrigin,
      allowedMessageType: this.allowedMessageType,
      timestampTolerance: this.timestampTolerance,
    };
  }
}

export const createMessageValidator = (allowedOrigin, options = {}) => {
  return new MessageValidator(allowedOrigin, MESSAGE_TYPES.AUTH_STATUS, options);
};
