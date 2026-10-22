import { memoizeAsync } from '~/lib/utils/memoize_async';

describe('memoizeAsync', () => {
  let fn;
  let memoized;

  beforeEach(() => {
    fn = jest.fn();
    memoized = memoizeAsync(fn);
  });

  describe('when the promise resolves', () => {
    beforeEach(() => {
      fn.mockImplementation((key) => Promise.resolve(`${key}!`));
    });

    it('resolves to its value', async () => {
      expect(await memoized('a')).toBe('a!');
    });

    it('calls through once per key', async () => {
      await memoized('a');
      await memoized('a');
      await memoized('b');

      expect(fn.mock.calls).toEqual([['a'], ['b']]);
    });
  });

  describe('when the promise rejects', () => {
    const error = new Error('Network Error');

    beforeEach(() => {
      fn.mockRejectedValueOnce(error).mockResolvedValue('ok');
    });

    it('rejects with its error', async () => {
      await expect(memoized('a')).rejects.toBe(error);
    });

    it('calls through again on the next call', async () => {
      await expect(memoized('a')).rejects.toBe(error);

      expect(await memoized('a')).toBe('ok');
      expect(fn).toHaveBeenCalledTimes(2);
    });
  });

  describe('when a call is still pending', () => {
    it('shares its promise', () => {
      fn.mockReturnValue(new Promise(() => {}));

      expect(memoized('a')).toBe(memoized('a'));
      expect(fn).toHaveBeenCalledTimes(1);
    });
  });
});
