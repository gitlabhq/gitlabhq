import { pageSingleton, clearPageSingleton } from '~/lib/utils/page_singleton';

describe('pageSingleton', () => {
  afterEach(() => {
    clearPageSingleton('key');
  });

  it('creates the value once and returns it on every call', () => {
    const create = jest.fn(() => ({}));

    const first = pageSingleton('key', create);

    expect(pageSingleton('key', create)).toBe(first);
    expect(create).toHaveBeenCalledTimes(1);
  });

  it('creates a new value after the key is cleared', () => {
    const first = pageSingleton('key', () => ({}));

    clearPageSingleton('key');

    expect(pageSingleton('key', () => ({}))).not.toBe(first);
  });

  it('shares the value with a second copy of the module', () => {
    let secondCopy;
    jest.isolateModules(() => {
      // eslint-disable-next-line global-require
      secondCopy = require('~/lib/utils/page_singleton');
    });

    const first = pageSingleton('key', () => ({}));

    expect(secondCopy.pageSingleton('key', () => ({}))).toBe(first);
  });
});
