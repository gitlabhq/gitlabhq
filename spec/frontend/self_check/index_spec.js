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

    describe('time out after one second', () => {
      it('(synchronous test)', () => {
        const startTime = new Date().getTime();
        while (new Date().getTime() - startTime < 2000) {
          // wait
        }
      });

      it('(asynchronous test)', done => {
        setTimeout(done, 2000);
      });
    });

    it('error in pending timeout', () => {
      setTimeout(() => {
        throw new Error('error in timeout');
      }, 1000);
    });
  });
});
