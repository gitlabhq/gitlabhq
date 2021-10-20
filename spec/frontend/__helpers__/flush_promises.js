export default function flushPromises() {
  return new Promise(setImmediate);
}
