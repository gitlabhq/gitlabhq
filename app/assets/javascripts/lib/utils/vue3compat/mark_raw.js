// this will  be replaced by markRaw from vue.js v3
export function markRaw(obj) {
  Object.defineProperty(obj, '__v_skip', {
    value: true,
    configurable: true,
  });

  return obj;
}
