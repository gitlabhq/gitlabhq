export function supported() {
  return Boolean(
    navigator.credentials &&
      navigator.credentials.create &&
      navigator.credentials.get &&
      window.PublicKeyCredential,
  );
}

export function isHTTPS() {
  return window.location.protocol.startsWith('https');
}

export const FLOW_AUTHENTICATE = 'authenticate';
export const FLOW_REGISTER = 'register';

// adapted from https://stackoverflow.com/a/21797381/8204697
function base64ToBuffer(base64) {
  const binaryString = window.atob(base64);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i += 1) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
}

// adapted from https://stackoverflow.com/a/9458996/8204697
function bufferToBase64(buffer) {
  if (typeof buffer === 'string') {
    return buffer;
  }

  let binary = '';
  const bytes = new Uint8Array(buffer);
  const len = bytes.byteLength;
  for (let i = 0; i < len; i += 1) {
    binary += String.fromCharCode(bytes[i]);
  }
  return window.btoa(binary);
}

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
