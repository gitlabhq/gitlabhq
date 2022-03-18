import { bufferToBase64, base64ToBase64Url } from '~/authentication/webauthn/util';
import { PKCE_CODE_CHALLENGE_DIGEST_ALGORITHM } from './constants';

// PKCE codeverifier should have a maximum length of 128 characters.
// Using 96 bytes generates a string of 128 characters.
// RFC: https://datatracker.ietf.org/doc/html/rfc7636#section-4.1
export const CODE_VERIFIER_BYTES = 96;

/**
 * Generate a cryptographically random string.
 * @param {Number} lengthBytes
 * @returns {String} a random string
 */
function getRandomString(lengthBytes) {
  // generate random values and load them into byteArray.
  const byteArray = new Uint8Array(lengthBytes);
  window.crypto.getRandomValues(byteArray);

  // Convert array to string
  const randomString = bufferToBase64(byteArray);
  return randomString;
}

/**
 * Creates a code verifier to be used for OAuth PKCE authentication.
 * The code verifier has 128 characters.
 *
 * RFC: https://datatracker.ietf.org/doc/html/rfc7636#section-4.1
 * @returns {String} code verifier
 */
export function createCodeVerifier() {
  const verifier = getRandomString(CODE_VERIFIER_BYTES);
  return base64ToBase64Url(verifier);
}

/**
 * Creates a code challenge for OAuth PKCE authentication.
 * The code challenge is derived from the given [codeVerifier].
 * [codeVerifier] is tranformed in the following way (as per the RFC):
 *    code_challenge = BASE64URL-ENCODE(SHA256(ASCII(codeVerifier)))
 *
 * RFC: https://datatracker.ietf.org/doc/html/rfc7636#section-4.2
 * @param {String} codeVerifier
 * @returns {String} code challenge
 */
export async function createCodeChallenge(codeVerifier) {
  // Generate SHA-256 digest of the [codeVerifier]
  const buffer = new TextEncoder().encode(codeVerifier);
  const digestArrayBuffer = await window.crypto.subtle.digest(
    PKCE_CODE_CHALLENGE_DIGEST_ALGORITHM.long,
    buffer,
  );

  // Convert digest to a Base64URL-encoded string
  const digestHash = bufferToBase64(digestArrayBuffer);
  // Escape string to remove reserved charaters
  const codeChallenge = base64ToBase64Url(digestHash);

  return codeChallenge;
}
