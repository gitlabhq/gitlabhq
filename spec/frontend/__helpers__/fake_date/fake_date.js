// Frida Kahlo's birthday (6 = July)
const DEFAULT_ARGS = [2020, 6, 6];

const RealDate = Date;

const isMocked = (val) => Boolean(val.mock);

const createFakeDateClass = (ctorDefaultParam = []) => {
  const ctorDefault = ctorDefaultParam.length ? ctorDefaultParam : DEFAULT_ARGS;

  const FakeDate = new Proxy(RealDate, {
    construct: (target, argArray) => {
      const ctorArgs = argArray.length ? argArray : ctorDefault;

      return new RealDate(...ctorArgs);
    },
    apply: (target, thisArg, argArray) => {
      const ctorArgs = argArray.length ? argArray : ctorDefault;

      return new RealDate(...ctorArgs).toString();
    },
    // We want to overwrite the default 'now', but only if it's not already mocked
    get: (target, prop) => {
      if (prop === 'now' && !isMocked(target[prop])) {
        return () => new RealDate(...ctorDefault).getTime();
      }

      return target[prop];
    },
    getPrototypeOf: (target) => {
      return target.prototype;
    },
    // We need to be able to set props so that `jest.spyOn` will work.
    set: (target, prop, value) => {
      // eslint-disable-next-line no-param-reassign
      target[prop] = value;
      return true;
    },
  });

  return FakeDate;
};

const setGlobalDateToFakeDate = (...args) => {
  const FakeDate = createFakeDateClass(args);
  global.Date = FakeDate;
};

const setGlobalDateToRealDate = () => {
  global.Date = RealDate;
};

// We use commonjs so that the test environment module can pick this up
// eslint-disable-next-line import/no-commonjs
module.exports = {
  setGlobalDateToFakeDate,
  setGlobalDateToRealDate,
  createFakeDateClass,
  RealDate,
};
