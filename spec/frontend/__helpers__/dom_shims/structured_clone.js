import { serialize, deserialize } from 'v8';

// Delegate to Node's V8 serializer, which implements the same algorithm as the browser. A `JSON`
// round trip is not equivalent: it accepts a Proxy, which the real algorithm rejects, so a spec
// cloning Vue 3 reactive state would pass here and fail in a browser.
//
// Note: This shim is added here mostly for completeness, use lodash's cloneDeep to avoid
// problems when handling reactive objects.
window.structuredClone = (item) => {
  try {
    return deserialize(serialize(item));
  } catch (error) {
    // V8 throws a plain `Error`; browsers throw a `DOMException` named `DataCloneError`.
    const domException = new Error(error.message);
    domException.name = 'DataCloneError';
    throw domException;
  }
};
