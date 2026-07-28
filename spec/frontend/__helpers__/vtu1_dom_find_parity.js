/* eslint-disable import/no-commonjs */
const VTU = require('@vue/test-utils');

// @vue/test-utils v1's find()/findAll() silently return component-capable
// wrappers when a string selector matches a component root ("find upgrade").
// @vue/test-utils v2 returns a DOMWrapper there, so specs relying on the
// upgrade break on the Vue 3 jest lane. Mirror the v2 contract at runtime:
// component-only wrapper APIs throw on string-selector find results, keeping
// the suite provably free of the pattern (the static check is
// `local-rules/vue3-find-component-upgrade`).
const COMPONENT_ONLY_API = [
  'props',
  'setProps',
  'setData',
  'emitted',
  'emittedByOrder',
  'destroy',
  'name',
  'isVueInstance',
];

const poison = (wrapper, selector) => {
  if (!wrapper?.vm) {
    return wrapper;
  }

  const fail = (api) => {
    throw new Error(
      `find('${selector}') matched a component root, and .${api} relies on the ` +
        `VTU v1 "find upgrade" that @vue/test-utils v2 does not provide. ` +
        `Use findComponent()/findComponentByTestId() instead.`,
    );
  };

  return new Proxy(wrapper, {
    get(target, prop) {
      if (prop === 'vm') {
        fail('vm');
      }
      if (COMPONENT_ONLY_API.includes(prop)) {
        return () => fail(`${prop}()`);
      }
      const value = Reflect.get(target, prop);
      if (typeof value !== 'function') {
        return value;
      }
      // Proxy invariant: non-configurable, non-writable data properties
      // (e.g. extendedWrapper's finders) must be returned as-is.
      const descriptor = Object.getOwnPropertyDescriptor(target, prop);
      if (descriptor && !descriptor.configurable && !descriptor.writable) {
        return value;
      }
      return value.bind(target);
    },
  });
};

if (global.document) {
  const vtu = VTU.default ?? VTU;
  const WrapperPrototype = vtu.Wrapper
    ? vtu.Wrapper.prototype
    : Object.getPrototypeOf(vtu.createWrapper(document.createElement('div')));

  const originalFind = WrapperPrototype.find;
  WrapperPrototype.find = function find(selector, ...rest) {
    const result = originalFind.call(this, selector, ...rest);
    return typeof selector === 'string' ? poison(result, selector) : result;
  };

  const originalFindAll = WrapperPrototype.findAll;
  WrapperPrototype.findAll = function findAll(selector, ...rest) {
    const result = originalFindAll.call(this, selector, ...rest);
    if (typeof selector === 'string' && result.wrappers) {
      // `wrappers` is a read-only property backed by a stable array; replace
      // its contents in place.
      result.wrappers.forEach((wrapper, index) => {
        result.wrappers[index] = poison(wrapper, selector);
      });
    }
    return result;
  };
}
