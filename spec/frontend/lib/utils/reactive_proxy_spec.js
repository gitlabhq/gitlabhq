import { reactiveOverride } from '~/lib/utils/reactive_proxy';

describe('reactiveOverride', () => {
  it('returns overridden property values', () => {
    const target = { a: 1, b: 2 };
    const proxy = reactiveOverride(target, { b: 99 });
    expect(proxy.b).toBe(99);
  });

  it('delegates non-overridden reads to the target', () => {
    const target = { a: 1, b: 2 };
    const proxy = reactiveOverride(target, { b: 99 });
    expect(proxy.a).toBe(1);
  });

  it('delegates writes to the target', () => {
    const target = { a: 1 };
    const proxy = reactiveOverride(target, { b: 99 });
    proxy.a = 42;
    expect(target.a).toBe(42);
  });

  it('does not modify the original target for overridden keys', () => {
    const target = { a: 1 };
    const proxy = reactiveOverride(target, { a: 99 });
    expect(proxy.a).toBe(99);
    expect(target.a).toBe(1);
  });

  it('reflects target mutations through the proxy', () => {
    const target = { a: 1 };
    const proxy = reactiveOverride(target, { b: 2 });
    target.a = 10;
    expect(proxy.a).toBe(10);
  });
});
