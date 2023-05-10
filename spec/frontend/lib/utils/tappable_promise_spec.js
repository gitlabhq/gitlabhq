import TappablePromise from '~/lib/utils/tappable_promise';

describe('TappablePromise', () => {
  it('allows a promise to have a progress indicator', () => {
    const pseudoProgress = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1];
    const progressCallback = jest.fn();
    const promise = new TappablePromise((tap, resolve) => {
      pseudoProgress.forEach(tap);
      resolve('done');

      return 'returned value';
    });

    return promise
      .tap(progressCallback)
      .then((val) => {
        expect(val).toBe('done');
        expect(val).not.toBe('returned value');

        expect(progressCallback).toHaveBeenCalledTimes(pseudoProgress.length);

        pseudoProgress.forEach((progress, index) => {
          expect(progressCallback).toHaveBeenNthCalledWith(index + 1, progress);
        });
      })
      .catch(() => {});
  });

  it('resolves with the value returned by the callback', () => {
    const promise = new TappablePromise((tap) => {
      tap(0.5);
      return 'test';
    });

    return promise
      .tap((progress) => {
        expect(progress).toBe(0.5);
      })
      .then((value) => {
        expect(value).toBe('test');
      });
  });

  it('allows a promise to be rejected', () => {
    const promise = new TappablePromise((tap, resolve, reject) => {
      reject(new Error('test error'));
    });

    return promise.catch((e) => {
      expect(e.message).toBe('test error');
    });
  });

  it('rejects the promise if the callback throws an error', () => {
    const promise = new TappablePromise(() => {
      throw new Error('test error');
    });

    return promise.catch((e) => {
      expect(e.message).toBe('test error');
    });
  });
});
