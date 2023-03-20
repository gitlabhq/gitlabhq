export function supported() {
  return Boolean(
    navigator.credentials?.create && navigator.credentials?.get && window.PublicKeyCredential,
  );
}

export function isHTTPS() {
  return window.location.protocol.startsWith('https');
}

/**
 * Converts a base64 string to an ArrayBuffer
 *
 * @param {String} str - A base64 encoded string
 * @returns {ArrayBuffer}
 */
export const base64ToBuffer = (str) => {
  const rawStr = atob(str);
  const buffer = new ArrayBuffer(rawStr.length);
  const arr = new Uint8Array(buffer);
  for (let i = 0; i < rawStr.length; i += 1) {
    arr[i] = rawStr.charCodeAt(i);
  }
  return arr.buffer;
};

/**
 * Converts ArrayBuffer to a base64-encoded string
 *
 * @param {ArrayBuffer, String} str -
 * @returns {String} - ArrayBuffer to a base64-encoded string.
 * When input is a string, returns the input as-is.
 */
export const bufferToBase64 = (input) => {
  if (typeof input === 'string') {
    return input;
  }
  const arr = new Uint8Array(input);
  return btoa(String.fromCharCode(...arr));
};

/**
 * Return a URL-safe base64 string.
 *
 * RFC: https://datatracker.ietf.org/doc/html/rfc4648#section-5
 * @param {String} base64Str
 * @returns {String}
 */
export const base64ToBase64Url = (base64Str) => {
  return base64Str.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
};

/**
 * Returns a copy of the given object with the id property converted to buffer
 *
 * @param {Object} param
 */
function convertIdToBuffer({ id, ...rest }) {
  return {
    ...rest,
    id: base64ToBuffer(id),
  };
}

/**
 * Returns a copy of the given array with all `id`s of the items converted to buffer
 *
 * @param {Array} items
 */
function convertIdsToBuffer(items) {
  return items.map(convertIdToBuffer);
}

/**
 * Returns an object with keys of the given props, and values from the given object converted to base64
 *
 * @param {String} obj
 * @param {Array} props
 */
function convertPropertiesToBase64(obj, props) {
  return props.reduce(
    (acc, property) => Object.assign(acc, { [property]: bufferToBase64(obj[property]) }),
    {},
  );
}

export function convertGetParams({ allowCredentials, challenge, ...rest }) {
  return {
    ...rest,
    ...(allowCredentials ? { allowCredentials: convertIdsToBuffer(allowCredentials) } : {}),
    challenge: base64ToBuffer(challenge),
  };
}

export function convertGetResponse(webauthnResponse) {
  return {
    type: webauthnResponse.type,
    id: webauthnResponse.id,
    rawId: bufferToBase64(webauthnResponse.rawId),
    response: convertPropertiesToBase64(webauthnResponse.response, [
      'clientDataJSON',
      'authenticatorData',
      'signature',
      'userHandle',
    ]),
    clientExtensionResults: webauthnResponse.getClientExtensionResults(),
  };
}

export function convertCreateParams({ challenge, user, excludeCredentials, ...rest }) {
  return {
    ...rest,
    challenge: base64ToBuffer(challenge),
    user: convertIdToBuffer(user),
    ...(excludeCredentials ? { excludeCredentials: convertIdsToBuffer(excludeCredentials) } : {}),
  };
}

export function convertCreateResponse(webauthnResponse) {
  return {
    type: webauthnResponse.type,
    id: webauthnResponse.id,
    rawId: bufferToBase64(webauthnResponse.rawId),
    clientExtensionResults: webauthnResponse.getClientExtensionResults(),
    response: convertPropertiesToBase64(webauthnResponse.response, [
      'clientDataJSON',
      'attestationObject',
    ]),
  };
}
