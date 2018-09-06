describe('frontend test suite self check', () => {
  describe('expected status: passed', () => {
    it('synchronous test', () => {
      expect(true).not.toBe(false);
    });

    it('asynchronous test', done => {
      done();
    });

    it('resolved Promise', () => Promise.resolve());
  });

  describe('expected status: failed', () => {
    describe('throws error', () => {
      it('(synchronous test)', () => {
        throw new Error('fail');
      });

      it('(asynchronous test)', done => {
        if (done) {
          throw new Error('fail');
        }
      });
    });

    it('rejected Promise', () => Promise.reject(new Error('rejected')));
  });
});
