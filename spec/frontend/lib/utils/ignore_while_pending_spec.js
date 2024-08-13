import waitForPromises from 'helpers/wait_for_promises';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';

const TEST_ARGS = [123, { foo: 'bar' }];

describe('~/lib/utils/ignore_while_pending', () => {
  let spyResolve;
  let spyReject;
  let spy;
  let subject;

  beforeEach(() => {
    spy = jest.fn().mockImplementation(() => {
      return new Promise((resolve, reject) => {
        spyResolve = resolve;
        spyReject = reject;
      });
    });
  });

  describe('with non-instance method', () => {
    beforeEach(() => {
      subject = ignoreWhilePending(spy);
    });

    it('while pending, will ignore subsequent calls', () => {
      subject(...TEST_ARGS);
      subject();
      subject();
      subject();

      expect(spy).toHaveBeenCalledTimes(1);
      expect(spy).toHaveBeenCalledWith(...TEST_ARGS);
    });

    it.each`
      desc               | act
      ${'when resolved'} | ${() => spyResolve()}
      ${'when rejected'} | ${() => spyReject(new Error('foo'))}
    `('$desc, can be triggered again', async ({ act }) => {
      // We need the empty catch(), since we are testing rejecting the promise,
      // which would otherwise cause the test to fail.
      subject(...TEST_ARGS).catch(() => {});
      subject();
      subject();
      subject();

      act();
      // We need waitForPromises, so that the underlying finally() runs.
      await waitForPromises();

      subject({ again: 'foo' });

      expect(spy).toHaveBeenCalledTimes(2);
      expect(spy).toHaveBeenCalledWith(...TEST_ARGS);
      expect(spy).toHaveBeenCalledWith({ again: 'foo' });
    });

    it('while pending, returns empty resolutions for ignored calls', async () => {
      subject(...TEST_ARGS);

      await expect(subject(...TEST_ARGS)).resolves.toBeUndefined();
      await expect(subject(...TEST_ARGS)).resolves.toBeUndefined();
    });

    it('when resolved, returns resolution for origin call', async () => {
      const resolveValue = { original: 1 };
      const result = subject(...TEST_ARGS);

      spyResolve(resolveValue);

      await expect(result).resolves.toEqual(resolveValue);
    });

    it('when rejected, returns rejection for original call', async () => {
      const rejectedErr = new Error('original');
      const result = subject(...TEST_ARGS);

      spyReject(rejectedErr);

      await expect(result).rejects.toEqual(rejectedErr);
    });
  });

  describe('with instance method', () => {
    let instance1;
    let instance2;

    beforeEach(() => {
      // Let's capture the "this" for tests
      subject = ignoreWhilePending(function instanceMethod(...args) {
        return spy(this, ...args);
      });

      instance1 = {};
      instance2 = {};
    });

    it('will not ignore calls across instances', () => {
      subject.call(instance1, { context: 1 });
      subject.call(instance1, {});
      subject.call(instance1, {});
      subject.call(instance2, { context: 2 });
      subject.call(instance2, {});

      expect(spy.mock.calls).toEqual([
        [instance1, { context: 1 }],
        [instance2, { context: 2 }],
      ]);
    });

    it('resolving one instance does not resolve other instances', async () => {
      subject.call(instance1, { context: 1 });

      // We need to save off spyResolve so it's not overwritten by next call
      const instance1Resolve = spyResolve;

      subject.call(instance2, { context: 2 });

      instance1Resolve();
      await waitForPromises();

      subject.call(instance1, { context: 1 });
      subject.call(instance2, { context: 2 });

      expect(spy.mock.calls).toEqual([
        [instance1, { context: 1 }],
        [instance2, { context: 2 }],
        [instance1, { context: 1 }],
      ]);
    });
  });
});
