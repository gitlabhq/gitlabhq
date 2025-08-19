import { s__ } from '~/locale';

export const generateSecureRandom = (length = 32) => {
  if (length <= 0 || !Number.isInteger(length)) {
    throw new Error(s__('Observability|Length must be a positive integer'));
  }

  if (!window.crypto?.getRandomValues || typeof window.crypto.getRandomValues !== 'function') {
    throw new Error(s__('Observability|Crypto API not available'));
  }

  const array = new Uint8Array(length);
  window.crypto.getRandomValues(array);

  return Array.from(array, (byte) => byte.toString(16).padStart(2, '0')).join('');
};

export const generateNonce = () => generateSecureRandom(16);
