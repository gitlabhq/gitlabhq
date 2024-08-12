export function test(received) {
  return received && typeof received === 'string' && received.startsWith('<');
}

// eslint-disable-next-line max-params
export function serialize(received, config, indentation, depth, refs, printer) {
  const parser = new DOMParser();
  const doc = parser.parseFromString(received, 'text/html');
  const el = doc.body.firstElementChild;

  return printer(el, config, indentation, depth, refs);
}
