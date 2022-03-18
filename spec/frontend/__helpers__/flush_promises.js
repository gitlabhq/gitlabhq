export default function flushPromises() {
  // eslint-disable-next-line no-restricted-syntax
  return new Promise(setImmediate);
}
